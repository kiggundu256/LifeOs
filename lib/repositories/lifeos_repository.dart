import '../data/app_database.dart';
import '../models/idea.dart';
import '../models/life_task.dart';

class LifeosRepository {
  LifeosRepository({AppDatabase? database}) : _database = database ?? AppDatabase.instance;
  final AppDatabase _database;

  int _now() => DateTime.now().millisecondsSinceEpoch;

  Future<List<LifeTask>> getTasks({String query = '', bool includeArchived = false}) async {
    final db = await _database.database;
    final where = <String>[];
    final args = <Object?>[];
    if (!includeArchived) where.add('is_archived = 0');
    final normalized = query.trim();
    if (normalized.isNotEmpty) {
      where.add('(title LIKE ? OR notes LIKE ?)');
      final pattern = '%$normalized%';
      args..add(pattern)..add(pattern);
    }
    final rows = await db.query(
      'tasks',
      where: where.isEmpty ? null : where.join(' AND '),
      whereArgs: args,
      orderBy: 'is_complete ASC, due_at IS NULL ASC, due_at ASC, updated_at DESC',
    );
    return rows.map(LifeTask.fromMap).toList(growable: false);
  }

  Future<int> saveTask({int? id, required String title, String notes = '', DateTime? dueAt, bool? isComplete}) async {
    final cleanTitle = title.trim();
    if (cleanTitle.isEmpty) throw ArgumentError('Task title cannot be empty.');
    final db = await _database.database;
    final now = _now();
    final values = <String, Object?>{
      'title': cleanTitle,
      'notes': notes.trim(),
      'due_at': dueAt?.millisecondsSinceEpoch,
      'updated_at': now,
    };
    if (id == null) {
      values.addAll({'is_complete': 0, 'is_archived': 0, 'created_at': now});
      return db.insert('tasks', values);
    }
    if (isComplete != null) values['is_complete'] = isComplete ? 1 : 0;
    final changed = await db.update('tasks', values, where: 'id = ?', whereArgs: [id]);
    if (changed == 0) throw StateError('Task $id no longer exists.');
    return id;
  }

  Future<void> setTaskComplete(int id, bool complete) async {
    final db = await _database.database;
    final changed = await db.update('tasks', {'is_complete': complete ? 1 : 0, 'updated_at': _now()}, where: 'id = ?', whereArgs: [id]);
    if (changed == 0) throw StateError('Task $id no longer exists.');
  }

  Future<void> archiveTask(int id, bool archived) async {
    final db = await _database.database;
    final changed = await db.update('tasks', {'is_archived': archived ? 1 : 0, 'updated_at': _now()}, where: 'id = ?', whereArgs: [id]);
    if (changed == 0) throw StateError('Task $id no longer exists.');
  }

  Future<void> deleteTask(int id) async {
    final db = await _database.database;
    await db.delete('tasks', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Idea>> getIdeas({String query = '', bool includeArchived = false}) async {
    final db = await _database.database;
    final where = <String>[];
    final args = <Object?>[];
    if (!includeArchived) where.add('is_archived = 0');
    final normalized = query.trim();
    if (normalized.isNotEmpty) {
      where.add('(title LIKE ? OR body LIKE ?)');
      final pattern = '%$normalized%';
      args..add(pattern)..add(pattern);
    }
    final rows = await db.query('ideas', where: where.isEmpty ? null : where.join(' AND '), whereArgs: args, orderBy: 'updated_at DESC');
    return rows.map(Idea.fromMap).toList(growable: false);
  }

  Future<int> saveIdea({int? id, required String title, String body = ''}) async {
    final cleanTitle = title.trim();
    if (cleanTitle.isEmpty) throw ArgumentError('Idea title cannot be empty.');
    final db = await _database.database;
    final now = _now();
    final values = <String, Object?>{'title': cleanTitle, 'body': body.trim(), 'updated_at': now};
    if (id == null) {
      values.addAll({'is_archived': 0, 'created_at': now});
      return db.insert('ideas', values);
    }
    final changed = await db.update('ideas', values, where: 'id = ?', whereArgs: [id]);
    if (changed == 0) throw StateError('Idea $id no longer exists.');
    return id;
  }

  Future<void> archiveIdea(int id, bool archived) async {
    final db = await _database.database;
    final changed = await db.update('ideas', {'is_archived': archived ? 1 : 0, 'updated_at': _now()}, where: 'id = ?', whereArgs: [id]);
    if (changed == 0) throw StateError('Idea $id no longer exists.');
  }

  Future<void> deleteIdea(int id) async {
    final db = await _database.database;
    await db.delete('ideas', where: 'id = ?', whereArgs: [id]);
  }

  Future<Map<String, int>> getTaskSummary() async {
    final db = await _database.database;
    final rows = await db.rawQuery('''
      SELECT COUNT(*) AS total,
             SUM(CASE WHEN is_complete = 1 THEN 1 ELSE 0 END) AS completed,
             SUM(CASE WHEN is_complete = 0 THEN 1 ELSE 0 END) AS open
      FROM tasks WHERE is_archived = 0
    ''');
    final row = rows.single;
    return {
      'total': (row['total'] as int?) ?? 0,
      'completed': (row['completed'] as int?) ?? 0,
      'open': (row['open'] as int?) ?? 0,
    };
  }

  Future<int> saveEvent({int? id, required String title, String notes = '', required DateTime startsAt, DateTime? endsAt, String? recurrenceRule}) async {
    final cleanTitle = title.trim();
    if (cleanTitle.isEmpty) throw ArgumentError('Event title cannot be empty.');
    if (endsAt != null && endsAt.isBefore(startsAt)) throw ArgumentError('Event end cannot be before its start.');
    final db = await _database.database;
    final now = _now();
    final values = <String, Object?>{
      'title': cleanTitle,
      'notes': notes.trim(),
      'starts_at': startsAt.millisecondsSinceEpoch,
      'ends_at': endsAt?.millisecondsSinceEpoch,
      'recurrence_rule': recurrenceRule?.trim().isEmpty == true ? null : recurrenceRule?.trim(),
      'updated_at': now,
    };
    if (id == null) {
      values.addAll({'is_archived': 0, 'created_at': now});
      return db.insert('events', values);
    }
    final changed = await db.update('events', values, where: 'id = ?', whereArgs: [id]);
    if (changed == 0) throw StateError('Event $id no longer exists.');
    return id;
  }

  Future<List<Map<String, Object?>>> getEvents({bool includeArchived = false}) async {
    final db = await _database.database;
    return db.query('events', where: includeArchived ? null : 'is_archived = 0', orderBy: 'starts_at ASC');
  }
}
