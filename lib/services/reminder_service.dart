import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

class ReminderService {
  ReminderService._();
  static final ReminderService instance = ReminderService._();
  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  bool _ready = false;
  bool _permissionChecked = false;

  Future<void> initialize({bool requestPermission = false}) async {
    if (!_ready) {
      tz_data.initializeTimeZones();
      const settings = InitializationSettings(android: AndroidInitializationSettings('@mipmap/ic_launcher'));
      await _plugin.initialize(settings);
      _ready = true;
    }
    if (requestPermission && !_permissionChecked) {
      _permissionChecked = true;
      final android = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      await android?.requestNotificationsPermission();
    }
  }

  Future<void> schedule({required int id, required String title, required String body, required DateTime at}) async {
    if (!at.isAfter(DateTime.now())) {
      await cancel(id);
      return;
    }
    await initialize(requestPermission: true);
    await _plugin.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(at, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'lifeos_reminders',
          'LifeOS reminders',
          channelDescription: 'Task deadlines and calendar reminders',
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      payload: 'lifeos:$id',
    );
  }

  Future<void> cancel(int id) async {
    await initialize();
    await _plugin.cancel(id);
  }

  Future<void> cancelEventRange(int eventId) async {
    await initialize();
    for (var index = 0; index < 100; index++) {
      await _plugin.cancel(eventId * 100 + index + 1);
    }
  }

  Future<void> cancelTask(int taskId) async => cancel(1000000000 + taskId);
}
