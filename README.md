# LifeOS — Phase 1 foundation

A local-first Flutter foundation for a private personal productivity and creative command-center Android app.

## Included in this phase

- Home dashboard with open/completed task counts and quick navigation.
- SQLite database stored in the app's private database directory.
- Tasks: create, edit, complete/uncomplete, search, archive/restore, and delete.
- Ideas: capture, edit, search, archive/restore, and delete.
- Planner: day, week, and month views; task deadlines; event creation, editing, archiving and deletion; daily, weekly, and monthly recurrence expansion; and scheduled local reminders.
- Database constraints and indexes, plus a versioned schema migration hook.
- Model mapping tests.

## Requirements

- Flutter SDK compatible with Dart 3.3 or newer.
- Android Studio or VS Code with Flutter/Dart tooling.
- Android device or emulator.

## Run

From this directory, first generate the Android platform folder if it is not present (this source bundle intentionally focuses on the app code):

```bash
flutter create --platforms=android .
flutter pub get
flutter analyze
flutter test
flutter run
```

## Phase 2 progress foundation

- Task completion and reopening transitions are now recorded as local activity history.
- Each activity stores the task ID, task-title snapshot, action, and timestamp so future progress charts can use historical data.
- Existing installations are upgraded with a versioned SQLite migration; existing tasks, ideas, and calendar events are preserved.
- The repository exposes typed, date-filterable task completion records.

## Performance & Growth dashboard

The app includes 7-, 30-, 90-day and all-history views; completion and reopening counts; daily averages; active-day counts; completion trend bars; a 28-day consistency map; current and best streaks; active/archived task balance; recent activity; and completion milestones. Task history is recorded locally and is not backfilled for activity before the tracking migration.

## Next product milestones

1. Expand Second Brain into a searchable vault with private attachments.
2. Add the Projects workspace and global Quick Capture.
3. Build Focus Guard and device usage controls.
4. Introduce the AI assistant with explicit privacy controls and local-first defaults.

## Planner and reminder behavior

- Planner recurrence is expanded locally for daily, weekly, and monthly events; monthly schedules retain their original day-of-month where possible.
- Task reminders and event reminders are scheduled as Android local notifications and are configured to be restored after device reboot.
- Android notification permission is requested when a reminder is first scheduled. Delivery time can still be affected by device battery restrictions and notification settings.

## Important scope notes

- Attachments, voice/image capture, AI, and Focus Guard remain planned follow-on work.
- SQLite database contents are app-private and local. This starter does not send user data to a server.
- Flutter's Android build and tests must be run with an installed Flutter SDK. The authoring environment used to prepare this starter did not have Flutter or Dart installed, so those commands have not been executed here.

## Suggested next steps

1. Expand Second Brain with private attachments and richer search.
2. Add the Projects workspace and global Quick Capture.
3. Build Focus Guard and device usage controls.
4. Introduce the AI assistant with explicit privacy controls and local-first defaults.

## Build an APK using GitHub Actions (no local Flutter installation needed)

1. Create a new GitHub repository and upload the contents of this folder to its `main` branch.
2. Open the repository's **Actions** tab and select **Build LifeOS Android APK** (or wait for the push-triggered build).
3. When the workflow finishes successfully, open that run and download the `lifeos-debug-apk` artifact.
4. Extract the downloaded artifact ZIP on your phone or computer; it contains `app-debug.apk`. Transfer it to your Android phone and install it. Android may ask you to allow installs from that source.

This is an unsigned release APK for personal testing, not a Play Store release. The workflow runs Flutter tests before building; if tests or compilation fail, the workflow will report the errors instead of producing an APK.
