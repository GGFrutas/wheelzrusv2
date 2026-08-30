---
name: odoo-integration
description: Conventions for backend/app/Http/Controllers code that talks to Odoo (dispatch.manager bookings, driver auth, milestones, consolidation). Use whenever adding or modifying an /odoo/* Laravel endpoint, an Odoo search_read/write call, or milestone/email logic.
---

# Odoo integration conventions

This backend has no real database model for bookings — Odoo (JSON-RPC) is the
system of record. Laravel is a thin auth + normalization layer in front of it.
`Transaction`/`RejectionReason`/`TransactionImage` Eloquent models exist but the
driver-facing endpoints (`FetchDataController`, `TransactionController`) bypass
them and talk to Odoo directly.

## Config: use `$this->odooUrl` / `$this->odooDb`, not hardcoded values

`App\Http\Controllers\Controller` (the abstract base) sets these in its
constructor from `config('odoo.odoo_url')` / `config('odoo.odoo_db')`, which
read `ODOO_URL` / `ODOO_DB` from `.env` (see `backend/config/odoo.php`).
`FetchDataController` already uses `$this->odooUrl`/`$this->odooDb`.

`TransactionController` still has its own legacy hardcoded
`protected $url`, `$db`, `$odoo_url` properties from before this config was
introduced — that's drift, not the pattern to copy. When you touch a method in
that file, prefer switching it to `$this->odooUrl . '/jsonrpc'` /
`$this->odooDb` instead of adding more hardcoded values.

## Always call Odoo through `jsonRpcRequest()`

`backend/app/Helpers/json_rpc_helper.php` defines a global `jsonRpcRequest($url, $payload)`
(autoloaded via `composer.json`'s `autoload.files`). It wraps Guzzle with a
30s timeout, trims trailing garbage Odoo sometimes appends after the last
`}`, and returns `['error' => '...']` (logged) instead of throwing on network
or JSON failures. Some older `TransactionController` methods still call
`file_get_contents($odooUrl, false, stream_context_create(...))` by hand —
that's legacy; new Odoo calls should use `jsonRpcRequest()` so failures are
handled/logged consistently.

Standard payload shape for a model call:
```php
jsonRpcRequest($odooUrl, [
    'jsonrpc' => '2.0',
    'method' => 'call',
    'params' => [
        'service' => 'object',
        'method' => 'execute_kw',
        'args' => [$db, $uid, $password, '<model>', '<search_read|write|search_count>', [$domain], ['fields' => $fields]],
    ],
    'id' => rand(1000, 9999),
]);
```
Login uses `'service' => 'common', 'method' => 'login'` instead (see
`authenticateDriver()`).

## Driver auth is per-request, via Odoo credentials — not Sanctum

Odoo-backed endpoints don't use Laravel sessions/Sanctum tokens. Every
request carries `?uid=<odoo_uid>` as a query param and `login`/`password`
headers (the driver's actual Odoo email/password). `FetchDataController::authenticateDriver()`
re-validates on every call: `common.login` → confirms uid, `res.users.search_read`
→ resolves `partner_id`, `res.partner.search_read` → checks `driver_access` is
true. If you add a new driver-scoped endpoint, call `authenticateDriver()`
first and bail out on its early-return responses (`if (!is_array($user)) return $user;`).
`TransactionController` methods are looser (mostly just check `uid` is
present) — don't take that as license to skip the driver_access check on new
endpoints; it's an inconsistency to avoid repeating.

## Every Odoo field needs a `fields` entry AND, usually, a `fieldsToString` entry

Odoo many2one fields come back as `[id, "Display Name"]` tuples, and missing
values as `false`. `FetchDataController::processDispatchManagers()` takes a
parallel `$fieldsToString` array and normalizes each listed field with:
- `null`/`false` → `""`
- `[id, "Label"]` → `"Label"`
- `bool` → `"true"`/`"false"`
- everything else → cast to string

If you add a new field to a `search_read`'s `fields` list because Flutter
needs it, also add it to `fieldsToString` (unless it's already a plain
scalar) — otherwise the frontend model parser gets a raw tuple/`false` and
breaks. Copy an existing endpoint's two arrays as your starting point rather
than writing a new pair from scratch; the four dispatch legs (`de_`, `pl_`,
`dl_`, `pe_`) each have the same field families (`_request_no`,
`_request_status`, `_truck_driver_name`, `_completion_time`, `_proof`,
`_signature`, `_proof_filename`).

## `dispatch_type` and freight-forwarder (`ff`) rows

`dispatch.manager` rows come in a few `dispatch_type`s; `'ff'` rows are
freight-forwarder bookings and are explicitly excluded from normal driver
queries (`['dispatch_type', '!=', 'ff']`) but then re-fetched separately by
matching `booking_reference_no` and merged back in (see
`getSecondScreenData`, `getTodayBooking`, `getAllBooking` — all do
"fetch driver legs → collect booking refs → fetch matching `ff` rows →
`array_merge`"). If you add a new listing endpoint that should show FF rows
alongside driver rows, follow that same two-step fetch-and-merge rather than
loosening the main domain filter.

## Milestones and status-change emails

`dispatch.milestone.history` rows track `scheduled_datetime`/`actual_datetime`
per `fcl_code` (e.g. `TYOT`, `TEOT`, `CLOT`, `GYDT`, `LCLDT`, ...).
`TransactionController::resolveMilestoneCode[/2/3]()` map
`(dispatch_type, which request-number leg fired, service_type, transport_mode)`
→ `fcl_code`. `updateMilestoneAndSendEmail()` then writes `actual_datetime` on
that milestone and, if the `fcl_code` has an entry in the `$fcl_code_email`
map, resolves an `ir.model.data` XML id to a `mail.template` id and calls
Odoo's `mail.template.send_mail`.

When adding a new status transition or leg: extend the relevant
`resolveMilestoneCode*` function first, then decide whether it needs a new
`fcl_code => 'module.xml_id'` entry in `$fcl_code_email` (some codes
intentionally have no template and just skip the email).

## Consolidation / backload / diverted bookings

`consolidationMaster()` and `divertedConsol()` in `TransactionController`
read `consol.type.notebook` (links a `pd.consol.master` to an
origin/destination `dispatch.manager` pair) and push status back into
`pd.consol.master.status`, the origin/destination `dispatch.manager.stage_id`,
and the matching `freight.management.stage_id`. These three models are kept
in sync together — if you change a stage transition for a consolidated
booking, check both origin and destination writes in whichever of these two
methods applies (`consolidationMaster` = normal backload, `divertedConsol` =
diverted, keyed off `type_consol`).

## New endpoint checklist

1. Add the route in `backend/routes/api.php` (grouped under the `HandleCors`
   middleware group, `/odoo/...` prefix by convention).
2. Controller method: call `authenticateDriver($request)` if driver-scoped.
3. Build `$domain`, `$fields`, `$fieldsToString` — copy the closest existing
   endpoint rather than writing from scratch.
4. Read via `processDispatchManagers(...)` (handles the ff-merge pattern too
   if needed) or write via `jsonRpcRequest()` directly.
5. Return `response()->json(['data' => ['transactions' => $data]])` — that's
   the shape every existing Flutter model/provider expects.
