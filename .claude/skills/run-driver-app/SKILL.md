---
name: run-driver-app
description: How to launch the Laravel backend and Flutter driver app together for manual testing on this project (WheelzRus/Yellox driver app). Use whenever asked to run, start, or test the app end-to-end, or when a device/emulator can't reach the backend.
---

# Running backend + frontend together

This is a two-process app: a Laravel API (`backend/`) fronting Odoo, and a
Flutter driver app (`frontend/`) that talks to that API over plain HTTP — not
`localhost`, because the app usually runs on a phone or emulator on the same
LAN as the backend.

## 1. Backend

```
cd backend
composer install          # first time only
php artisan serve --host=0.0.0.0 --port=8000
```
Binding `0.0.0.0` (not the default `127.0.0.1`) is required — otherwise a
phone/emulator on the LAN can't reach it at all.

Odoo connection comes from `.env` (`ODOO_URL`, `ODOO_DB`), read via
`backend/config/odoo.php`. The checked-in defaults point at
`http://gsq-ibx-rda:8068` / db `rda_beta_new` — an internal Odoo instance, so
this only works from the office network/VPN. There's no local Odoo mock;
without connectivity to that host, every `/odoo/*` endpoint will fail at the
`jsonRpcRequest()` call.

## 2. Frontend — point it at the backend's LAN IP

The API base URL is **not** read from any `.env`/config file — it's a
hardcoded string in two separate places, and both need to match wherever you
ran `php artisan serve` in step 1:

- `frontend/lib/provider/base_url_provider.dart` — `baseUrlProvider`
- `frontend/lib/services/auth_service.dart` — `AuthService`'s `Dio` `baseUrl`
  (currently includes `/api` and is used only by the login flow; everything
  else reads `base_url_provider`)

Find your machine's LAN IP (`ipconfig` on Windows) and update both constants
if it differs from what's currently checked in (`10.174.185.53` at time of
writing). Use the real LAN IP (not the Android emulator's `10.0.2.2` alias)
in both places — it works for the emulator and physical devices alike as
long as they're on the same network as the machine running `php artisan serve`.

```
cd frontend
flutter pub get
flutter devices            # confirm target device/emulator id
flutter run -d <device-id>
```

## 3. Logging in

There's no local test-user shortcut — login exchanges an **Odoo** email +
password for a uid (`AuthenticationController::login` →
`authenticateOdooUser`), and every subsequent Odoo-backed screen attaches
that uid as a query param plus `login`/`password` headers (see
[[odoo-integration]] for the request shape). To see booking/transaction
screens with real data, the Odoo user must additionally have
`driver_access = true` on their `res.partner` record — a valid Odoo login
without that flag will authenticate but get rejected by
`FetchDataController::authenticateDriver()` as "Not a driver".

## 4. Permissions to grant on first run

The app requests notification permission on startup (`NotificationService.requestPermission()`)
and camera/storage/location permissions when you reach proof-of-delivery,
photo-attachment, or map screens. Deny one and the corresponding feature
degrades silently rather than erroring loudly — e.g. a denied notification
permission means offline-queued PODs (see [[flutter-offline-sync]]) still
upload on schedule, you just won't see the "Upload Successful" toast.
