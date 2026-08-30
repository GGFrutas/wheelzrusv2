---
name: flutter-offline-sync
description: How the Flutter app queues proof-of-delivery uploads in Hive and retries them via Workmanager + local notifications. Use when touching offline upload/sync, Hive boxes/adapters, Workmanager background tasks, or notification_service.dart / assignment_notification_service.dart.
---

# Offline upload queue conventions

Drivers use this app in areas with poor connectivity, so proof-of-delivery
(POD) submissions must not be lost just because a request fails. The pattern
is: queue in Hive on failure, drain the queue from a periodic background
task, notify locally when something finally uploads.

## The pieces

- `frontend/lib/models/pod_offline_model.dart` — `PodModel` (Hive
  `TypeAdapter`, generated via `hive_generator`/`build_runner`) stores the
  raw HTTP request that needs to happen: `uri`, `headers`, `body`, plus an
  `isUploading` flag.
- `frontend/lib/provider/hive_offline_provider.dart` — `PendingPodUploader.uploadPendingPods()`
  opens the `pendingPods` Hive box, `http.post`s each stored request, deletes
  the entry on a `200`, and resets `isUploading = false` (leaving it queued)
  on any failure or exception. A `bool _isUploadingPendingPods` guard makes
  concurrent calls to the drain no-op instead of double-uploading.
- `frontend/lib/main.dart` registers a Workmanager periodic task
  (`"uploadPendingPodsTask"`, every 15 minutes, `NetworkType.connected`
  constraint) whose `callbackDispatch()` re-initializes Hive + notifications
  in the background isolate and calls `PendingPodUploader().uploadPendingPods()`.
  This runs even if the app has been killed.
- `frontend/lib/services/notification_service.dart` — `NotificationService.showNotification()`
  fires a local "Upload Successful" notification per request number the
  drain succeeded on; `showAssignmentNotification()` is a separate
  notification type for newly-assigned bookings.
- `frontend/lib/services/assignment_notification_service.dart` —
  `AssignmentNotificationService.checkAndNotifyNewAssignments()` diffs the
  driver's current transaction list against a `seen_request_numbers`
  `SharedPreferences` set to decide which assignments are "new" since last
  check, and suppresses all notifications on the very first run (so
  installing the app doesn't fire a notification storm for existing
  bookings).

## Adding a new offline-capable upload

Follow the existing shape rather than building a parallel mechanism:

1. If it's just another POD-like upload (same request/response shape), queue
   it as a `PodModel` and let the existing `PendingPodUploader` drain it —
   don't write a second uploader class.
2. If it's a genuinely different payload shape, add a new Hive model +
   generated adapter, but be careful with adapter **type IDs**: `PodModelAdapter`
   is registered at index `0` (`Hive.registerAdapter(PodModelAdapter())` uses
   the `@HiveType(typeId: ...)` baked into the generated adapter). A new
   model needs its own unused typeId — reusing one silently corrupts
   whichever box opens second. Register the new adapter in **both**
   `main()` and `callbackDispatch()` in `main.dart` — the background isolate
   re-initializes Hive independently and needs every adapter it might touch.
3. Drain the new queue from inside the same Workmanager task (or add a
   second `registerPeriodicTask` only if it genuinely needs a different
   schedule/constraints) so there's one background-sync story, not several.
4. If successful uploads should notify the driver, add a method to
   `NotificationService` rather than constructing `AndroidNotificationDetails`
   inline elsewhere.

## Gotchas

- `uploadPendingPods()` returns silently (`[]`) if another drain is already
  in-flight — don't assume calling it always processes the queue.
- A pod stuck with `isUploading = true` after an app crash mid-upload will be
  skipped by the loop (`if (pod.isUploading) continue;`) until something
  resets the flag — there's no timeout/self-heal for that case today, so if
  you see PODs stuck forever in the box, check for exactly this.
- `AssignmentNotificationService`'s "seen" set is a single `SharedPreferences`
  list, not namespaced per logged-in driver beyond reading `partner_id` once
  for filtering candidates — switching drivers on the same device without
  clearing prefs can carry over "seen" state from the previous driver.
