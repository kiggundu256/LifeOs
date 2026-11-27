import 'package:flutter_test/flutter_test.dart';
import 'package:lifeos/models/focus_session.dart';

void main() {
  test('focus session maps timestamps and duration', () {
    final started = DateTime(2026, 11, 27, 9);
    final session = FocusSession.fromMap({'id': 7, 'started_at': started.millisecondsSinceEpoch, 'ended_at': started.add(const Duration(minutes: 25)).millisecondsSinceEpoch, 'planned_minutes': 25, 'focused_seconds': 1500, 'status': 'completed'});
    expect(session.id, 7);
    expect(session.startedAt, started);
    expect(session.duration, const Duration(minutes: 25));
    expect(session.status, 'completed');
  });
}
