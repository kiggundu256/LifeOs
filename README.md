# LifeOS — Personal productivity and knowledge workspace

LifeOS is a private, local-first Flutter productivity and creative command-center app.

## Included capabilities
- Home dashboard, tasks and task completion history.
- Performance & Growth analytics with trends, streaks and consistency history.
- Planner calendar with recurring events and Android local reminders.
- Second Brain searchable notes, folders, tags, pinning and private attachments.
- Projects with linked tasks, milestones, notes and private attachments.
- Quick Capture inbox that converts captures into tasks, notes and Planner events.
- LifeOS AI assistant with configurable OpenAI-compatible providers.

## AI assistant and privacy
- Configure an OpenAI-compatible HTTPS endpoint, model name and API key from the AI screen.
- API keys are stored with Android secure storage and are not included in source code or SQLite.
- LifeOS context sharing is off by default. When explicitly enabled, a limited snapshot of open tasks, Second Brain notes, projects and inbox captures is sent to the configured provider with the request.
- Attachments and API keys are never added to the context snapshot.
- AI responses are advisory. The assistant cannot silently modify tasks, projects, notes or reminders.
- AI provider usage may incur charges according to the provider's pricing. LifeOS does not include a bundled API key.

## Build
```bash
flutter create --platforms=android --project-name lifeos .
dart tool/configure_android_notifications.dart
flutter pub get
flutter analyze
flutter test
flutter run
```
GitHub Actions runs Dart analysis, Flutter tests and a release APK build on pull requests and main-branch updates. Download the `LifeOS-Android-APK` artifact from a successful workflow run.
