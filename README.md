# LifeOS — Phase 1 foundation

A local-first Flutter foundation for a private personal productivity and creative command-center Android app.

## Included in this phase

- Home dashboard with open/completed task counts and quick navigation.
- SQLite database stored in the app's private database directory.
- Tasks: create, edit, complete/uncomplete, search, archive/restore, and delete.
- Ideas: capture, edit, search, archive/restore, and delete.
- Calendar: create and list appointments, with a basic daily/weekly/monthly recurrence rule stored for future recurrence handling.
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

1. Add a Performance & Growth screen with daily and weekly completion charts.
2. Complete calendar recurrence generation and event editing, archiving, and deletion.
3. Expand the idea vault into a searchable Second Brain with private attachments.
4. Add the Projects workspace and global Quick Capture.
5. Add reminders, notifications, and Focus Guard.
6. Introduce the AI assistant with explicit privacy controls and local-first defaults.

## Important scope notes

- The recurrence rule is saved, but recurring event occurrence generation is not implemented yet.
- Attachments, voice/image capture, notifications, AI, Performance & Growth analytics, and Focus Guard are planned follow-on work.
- SQLite database contents are app-private and local. This starter does not send user data to a server.
- Flutter's Android build and tests must be run with an installed Flutter SDK. The authoring environment used to prepare this starter did not have Flutter or Dart installed, so those commands have not been executed here.

## Suggested next steps

1. Run the three verification commands above on the development machine.
2. Add repository-level database tests using an in-memory SQLite test adapter.
3. Implement recurrence generation and event edit/archive/delete UI.
4. Add attachment metadata and app-private file storage.
5. Add task review history before implementing Performance & Growth charts.

## Build an APK using GitHub Actions (no local Flutter installation needed)

1. Create a new GitHub repository and upload the contents of this folder to its `main` branch.
2. Open the repository's **Actions** tab and select **Build LifeOS Android APK** (or wait for the push-triggered build).
3. When the workflow finishes successfully, open that run and download the `lifeos-debug-apk` artifact.
4. Extract the downloaded artifact ZIP on your phone or computer; it contains `app-debug.apk`. Transfer it to your Android phone and install it. Android may ask you to allow installs from that source.

This is an unsigned debug build for personal testing, not a Play Store release. The workflow runs Flutter tests before building; if tests or compilation fail, the workflow will report the errors instead of producing an APK.
