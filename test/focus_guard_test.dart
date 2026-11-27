import 'package:flutter_test/flutter_test.dart';
import 'package:lifeos/models/focus_session.dart';
import 'package:lifeos/services/usage_stats_service.dart';

void main() {
  test('usage entry maps Android usage data and exposes duration', () {
    final entry = AppUsageEntry.fromMap({'packageName': 'com.example.video', 'appName': 'Video', 'foregroundMillis': 125000});
    expect(entry.packageName, 'com.example.video');
    expect(entry.appName, 'Video');
    expect(entry.duration, const Duration(minutes: 2, seconds: 5));
  });

  test('focus session maps timestamps and duration', () {
    final started = DateTime(2026, 11, 27, 9);
    final session = FocusSession.fromMap({'id': 7, 'started_at': started.millisecondsSinceEpoch, 'ended_at': started.add(const Duration(minutes: 25)).millisecondsSinceEpoch, 'planned_minutes': 25, 'focused_seconds': 1500, 'status': 'completed'});
    expect(session.id, 7);
    expect(session.startedAt, started);
    expect(session.duration, const Duration(minutes: 25));
    expect(session.status, 'completed');
  });
}
