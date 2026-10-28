import 'package:flutter_test/flutter_test.dart';
import 'package:lifeos/models/idea.dart';
import 'package:lifeos/models/life_task.dart';

void main() {
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
}
