# LifeOS — Personal productivity and knowledge workspace

A local-first Flutter foundation for a private personal productivity and creative command-center Android app.

## Included in this phase

- Home dashboard with open/completed task counts and quick navigation.
- SQLite database stored in the app's private database directory.
- Tasks: create, edit, complete/uncomplete, search, archive/restore, and delete.
- Second Brain: searchable notes, folders, tags, pinning, archive/restore, and private file attachments.
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
flutter create --platforms=android --project-name lifeos .
dart tool/configure_android_notifications.dart
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

## Second Brain vault\n\n- Existing Ideas are retained and upgraded in place as notes; the SQLite v4 migration preserves their titles, bodies, archive state, and timestamps.\n- Notes can be organized into folders, tagged, pinned, searched across titles/body/tags, archived, restored, and permanently deleted.\n- File attachments are copied into the app-private `second_brain/attachments` directory; only metadata and private paths are stored in SQLite. Attachments are not uploaded to a server.\n- Attachments can be opened with a compatible Android app, added to existing notes, or removed from the vault. Deleting a note also removes its private attachment copies.\n\n## Planner and reminder behavior

- Planner recurrence is expanded locally for daily, weekly, and monthly events; monthly schedules retain their original day-of-month where possible.
- Task reminders and event reminders are scheduled as Android local notifications, restored after device reboot, and reconciled for the next 90 days whenever the Planner initializes.
- Android notification permission is requested when a reminder is first scheduled. Delivery time can still be affected by device battery restrictions and notification settings.

## Important scope notes

- Attachments, voice/image capture, AI, and Focus Guard remain planned follow-on work.
- SQLite database contents are app-private and local. This starter does not send user data to a server.
- The GitHub Actions workflow runs Dart analysis, unit tests, and a release APK build on every pull request and main-branch update.

## Suggested next steps

1. Expand the Projects workspace and global Quick Capture.
2. Add the Projects workspace and global Quick Capture.
3. Build Focus Guard and device usage controls.
4. Introduce the AI assistant with explicit privacy controls and local-first defaults.

## Build an APK using GitHub Actions (no local Flutter installation needed)

1. Open this repository's **Actions** tab.
2. Open the latest successful **LifeOS Android quality checks and APK** run.
3. Download the `LifeOS-Android-APK` artifact and extract `app-release.apk`.
4. Transfer the APK to your Android phone and install it. Android may ask you to allow installs from that source.

This is a personal-use release APK, not a Play Store production-signed build. The workflow runs Flutter tests before building; if tests or compilation fail, the workflow will report the errors instead of producing an APK.
