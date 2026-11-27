import 'package:flutter_test/flutter_test.dart';
import 'package:lifeos/models/idea.dart';
import 'package:lifeos/models/life_task.dart';
import 'package:lifeos/models/task_completion_record.dart';
import 'package:lifeos/models/performance_data.dart';
import 'package:lifeos/models/planner_recurrence.dart';

void main() {
  group('PlannerRecurrence', () {
    test('expands daily and weekly events within the selected range', () {
      final start = DateTime(2026, 11, 1, 9);
      final dates = PlannerRecurrence.occurrences(startsAt: start, rule: 'daily', from: DateTime(2026, 11, 3), to: DateTime(2026, 11, 6));
      expect(dates, [DateTime(2026, 11, 3, 9), DateTime(2026, 11, 4, 9), DateTime(2026, 11, 5, 9)]);
      final weekly = PlannerRecurrence.occurrences(startsAt: start, rule: 'weekly', from: DateTime(2026, 11, 1), to: DateTime(2026, 12, 1));
      expect(weekly.length, 5);
    });

    test('monthly recurrence clamps to month end without drifting anchor day', () {
      final dates = PlannerRecurrence.occurrences(startsAt: DateTime(2026, 1, 31, 8), rule: 'monthly', from: DateTime(2026, 1, 1), to: DateTime(2026, 5, 1));
      expect(dates, [DateTime(2026, 1, 31, 8), DateTime(2026, 2, 28, 8), DateTime(2026, 3, 31, 8), DateTime(2026, 4, 30, 8)]);
    });

    test('one-off events appear only when inside the range', () {
      final dates = PlannerRecurrence.occurrences(startsAt: DateTime(2026, 11, 5), rule: null, from: DateTime(2026, 11, 1), to: DateTime(2026, 11, 5));
      expect(dates, isEmpty);
    });
  });

  group('LifeTask.fromMap', () {
    test('maps stored values and nullable due date', () {
      final created = DateTime(2026, 10, 26, 10).millisecondsSinceEpoch;
      final updated = DateTime(2026, 10, 26, 11).millisecondsSinceEpoch;
      final due = DateTime(2026, 10, 27).millisecondsSinceEpoch;
      final task = LifeTask.fromMap({
        'id': 7,
        'title': 'Edit video',
        'notes': 'Prepare footage first',
        'is_complete': 1,
        'is_archived': 0,
        'due_at': due,
        'created_at': created,
        'updated_at': updated,
      });
      expect(task.id, 7);
      expect(task.title, 'Edit video');
      expect(task.isComplete, isTrue);
      expect(task.isArchived, isFalse);
      expect(task.dueAt, DateTime.fromMillisecondsSinceEpoch(due));
      expect(task.reminderAt, isNull);
    });

    test('defaults optional fields safely', () {
      final now = DateTime(2026, 10, 26).millisecondsSinceEpoch;
      final task = LifeTask.fromMap({
        'id': 1,
        'title': 'Read',
        'created_at': now,
        'updated_at': now,
      });
      expect(task.notes, isEmpty);
      expect(task.isComplete, isFalse);
      expect(task.isArchived, isFalse);
      expect(task.dueAt, isNull);
    });
  });

  test('Idea.fromMap maps archive and body values', () {
    final now = DateTime(2026, 10, 26).millisecondsSinceEpoch;
    final idea = Idea.fromMap({
      'id': 3,
      'title': 'Editing competition show',
      'body': 'Give everyone the same footage',
      'is_archived': 1,
      'created_at': now,
      'updated_at': now,
    });
    expect(idea.id, 3);
    expect(idea.body, contains('same footage'));
    expect(idea.isArchived, isTrue);
  });
  group('TaskCompletionRecord.fromMap', () {
    test('maps a completed task activity', () {
    final occurred = DateTime(2026, 11, 27, 9).millisecondsSinceEpoch;
    final record = TaskCompletionRecord.fromMap({'id': 4, 'task_id': 12, 'task_title': 'Finish LifeOS', 'action': 'completed', 'occurred_at': occurred});
    expect(record.id, 4);
    expect(record.taskId, 12);
    expect(record.taskTitle, 'Finish LifeOS');
    expect(record.isCompletion, isTrue);
    expect(record.occurredAt, DateTime.fromMillisecondsSinceEpoch(occurred));
    });
  });
  group('PerformanceData', () {
    test('keeps task balances and completion activity', () {
      const data = PerformanceData(activeTasks: 5, completedTasks: 2, openTasks: 3, archivedTasks: 1, activity: []);
      expect(data.activeTasks, 5);
      expect(data.completedTasks, 2);
      expect(data.openTasks, 3);
      expect(data.archivedTasks, 1);
      expect(data.activity, isEmpty);
    });
  });
}



