import 'package:flutter_test/flutter_test.dart';
import 'package:lifeos/models/life_project.dart';

void main() {
  group('LifeProject', () {
    test('maps project fields and dates from SQLite rows', () {
      final start = DateTime(2026, 1, 2).millisecondsSinceEpoch;
      final due = DateTime(2026, 2, 3).millisecondsSinceEpoch;
      final project = LifeProject.fromMap({
        'id': 7,
        'title': 'LifeOS',
        'description': 'Personal workspace',
        'objective': 'Ship a useful app',
        'priority': 'high',
        'status': 'active',
        'start_at': start,
        'due_at': due,
        'is_archived': 0,
        'created_at': start,
        'updated_at': due,
      });
      expect(project.id, 7);
      expect(project.title, 'LifeOS');
      expect(project.priority, 'high');
      expect(project.status, 'active');
      expect(project.startAt, DateTime.fromMillisecondsSinceEpoch(start));
      expect(project.dueAt, DateTime.fromMillisecondsSinceEpoch(due));
      expect(project.isArchived, isFalse);
    });

    test('supports legacy optional values and archived projects', () {
      final stamp = DateTime(2026).millisecondsSinceEpoch;
      final project = LifeProject.fromMap({
        'id': 1,
        'title': 'Legacy',
        'created_at': stamp,
        'updated_at': stamp,
        'is_archived': 1,
      });
      expect(project.description, '');
      expect(project.objective, '');
      expect(project.priority, 'medium');
      expect(project.status, 'active');
      expect(project.startAt, isNull);
      expect(project.dueAt, isNull);
      expect(project.isArchived, isTrue);
    });
  });
}
