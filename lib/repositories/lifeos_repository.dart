import '../data/app_database.dart';
import '../models/idea.dart';
import '../models/life_task.dart';
import '../models/task_completion_record.dart';
import '../models/performance_data.dart';

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

  Future<int> saveTask({int? id, required String title, String notes = '', DateTime? dueAt, DateTime? reminderAt, bool? isComplete}) async {
    final cleanTitle = title.trim();
    if (cleanTitle.isEmpty) throw ArgumentError('Task title cannot be empty.');
    final db = await _database.database;
    final now = _now();
    final values = <String, Object?>{
      'title': cleanTitle,
      'notes': notes.trim(),
      'due_at': dueAt?.millisecondsSinceEpoch,
      'reminder_at': reminderAt?.millisecondsSinceEpoch,
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
    await db.transaction((txn) async {
      final rows = await txn.query('tasks', columns: ['title', 'is_complete'], where: 'id = ?', whereArgs: [id], limit: 1);
      if (rows.isEmpty) throw StateError('Task $id no longer exists.');
      final row = rows.single;
      final wasComplete = (row['is_complete'] as int) == 1;
      if (wasComplete == complete) return;
      final now = _now();
      await txn.update('tasks', {'is_complete': complete ? 1 : 0, 'updated_at': now}, where: 'id = ?', whereArgs: [id]);
      await txn.insert('task_completion_history', {'task_id': id, 'task_title': row['title'] as String, 'action': complete ? 'completed' : 'reopened', 'occurred_at': now});
    });
  }

  Future<List<TaskCompletionRecord>> getTaskCompletionHistory({DateTime? from, DateTime? to}) async {
    final db = await _database.database;
    final where = <String>[];
    final args = <Object?>[];
    if (from != null) { where.add('occurred_at >= ?'); args.add(from.millisecondsSinceEpoch); }
    if (to != null) { where.add('occurred_at < ?'); args.add(to.millisecondsSinceEpoch); }
    final rows = await db.query('task_completion_history', where: where.isEmpty ? null : where.join(' AND '), whereArgs: args, orderBy: 'occurred_at DESC, id DESC');
    return rows.map(TaskCompletionRecord.fromMap).toList(growable: false);
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

  Future<int> saveIdea({int? id, required String title, String body = '', int? folderId, bool isPinned = false, List<String> tags = const []}) async {
    final cleanTitle = title.trim();
    if (cleanTitle.isEmpty) throw ArgumentError('Note title cannot be empty.');
    final db = await _database.database;
    final now = _now();
    final cleanTags = tags.map((tag) => tag.trim().replaceFirst(RegExp(r'^#'), '')).where((tag) => tag.isNotEmpty).toSet();
    return db.transaction((txn) async {
      final values = <String, Object?>{
        'title': cleanTitle, 'body': body.trim(), 'folder_id': folderId,
        'is_pinned': isPinned ? 1 : 0, 'updated_at': now,
      };
      int noteId;
      if (id == null) {
        values.addAll({'is_archived': 0, 'created_at': now});
        noteId = await txn.insert('ideas', values);
      } else {
        final changed = await txn.update('ideas', values, where: 'id = ?', whereArgs: [id]);
        if (changed == 0) throw StateError('Note $id no longer exists.');
        noteId = id;
      }
      await txn.delete('idea_tags', where: 'idea_id = ?', whereArgs: [noteId]);
      for (final tag in cleanTags) {
        await txn.rawInsert(
          'INSERT OR IGNORE INTO brain_tags(name, created_at) VALUES (?, ?)',
          [tag, now],
        );
        final rows = await txn.query('brain_tags', columns: ['id'], where: 'name = ?', whereArgs: [tag], limit: 1);
        await txn.insert('idea_tags', {'idea_id': noteId, 'tag_id': rows.single['id']});
      }
      return noteId;
    });
  }

  Future<List<Map<String, Object?>>> getBrainNotes({
    String query = '', bool includeArchived = false, bool pinnedOnly = false,
    int? folderId, int? tagId,
  }) async {
    final db = await _database.database;
    final clauses = <String>[];
    final args = <Object?>[];
    clauses.add('ideas.is_archived = ?'); args.add(includeArchived ? 1 : 0);
    if (pinnedOnly) clauses.add('ideas.is_pinned = 1');
    if (folderId != null) { clauses.add('ideas.folder_id = ?'); args.add(folderId); }
    if (tagId != null) {
      clauses.add('EXISTS (SELECT 1 FROM idea_tags it WHERE it.idea_id = ideas.id AND it.tag_id = ?)');
      args.add(tagId);
    }
    final term = query.trim();
    if (term.isNotEmpty) {
      clauses.add('''(
        ideas.title LIKE ? OR ideas.body LIKE ? OR
        EXISTS (SELECT 1 FROM idea_tags search_it JOIN brain_tags search_t ON search_t.id = search_it.tag_id
                WHERE search_it.idea_id = ideas.id AND search_t.name LIKE ?)
      )''');
      final pattern = '%$term%'; args..add(pattern)..add(pattern)..add(pattern);
    }
    return db.rawQuery('''
      SELECT ideas.*, brain_folders.name AS folder_name,
        (SELECT group_concat(brain_tags.name, ',') FROM idea_tags
         JOIN brain_tags ON brain_tags.id = idea_tags.tag_id WHERE idea_tags.idea_id = ideas.id) AS tag_names,
        (SELECT COUNT(*) FROM idea_attachments WHERE idea_attachments.idea_id = ideas.id) AS attachment_count
      FROM ideas LEFT JOIN brain_folders ON brain_folders.id = ideas.folder_id
      WHERE ${clauses.join(' AND ')}
      ORDER BY ideas.is_pinned DESC, ideas.updated_at DESC
    ''', args);
  }

  Future<List<Map<String, Object?>>> getBrainFolders() async {
    final db = await _database.database;
    return db.query('brain_folders', orderBy: 'name COLLATE NOCASE');
  }

  Future<int> saveBrainFolder(String name) async {
    final clean = name.trim();
    if (clean.isEmpty) throw ArgumentError('Folder name cannot be empty.');
    final db = await _database.database;
    final now = _now();
    await db.rawInsert('INSERT OR IGNORE INTO brain_folders(name, created_at, updated_at) VALUES (?, ?, ?)', [clean, now, now]);
    final rows = await db.query('brain_folders', columns: ['id'], where: 'name = ?', whereArgs: [clean], limit: 1);
    return rows.single['id'] as int;
  }

  Future<void> deleteBrainFolder(int id) async {
    final db = await _database.database;
    await db.delete('brain_folders', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Map<String, Object?>>> getBrainTags() async {
    final db = await _database.database;
    return db.rawQuery('''
      SELECT brain_tags.*, COUNT(idea_tags.idea_id) AS note_count
      FROM brain_tags LEFT JOIN idea_tags ON idea_tags.tag_id = brain_tags.id
      GROUP BY brain_tags.id ORDER BY brain_tags.name COLLATE NOCASE
    ''');
  }

  Future<List<String>> getIdeaTagNames(int ideaId) async {
    final db = await _database.database;
    final rows = await db.rawQuery('''
      SELECT brain_tags.name FROM brain_tags
      JOIN idea_tags ON idea_tags.tag_id = brain_tags.id
      WHERE idea_tags.idea_id = ? ORDER BY brain_tags.name COLLATE NOCASE
    ''', [ideaId]);
    return rows.map((row) => row['name'] as String).toList(growable: false);
  }

  Future<void> setIdeaPinned(int id, bool pinned) async {
    final db = await _database.database;
    final changed = await db.update('ideas', {'is_pinned': pinned ? 1 : 0, 'updated_at': _now()}, where: 'id = ?', whereArgs: [id]);
    if (changed == 0) throw StateError('Note $id no longer exists.');
  }

  Future<int> addIdeaAttachment({
    required int ideaId, required String displayName, required String storedPath,
    String? mimeType, required int sizeBytes,
  }) async {
    final db = await _database.database;
    return db.insert('idea_attachments', {
      'idea_id': ideaId, 'display_name': displayName, 'stored_path': storedPath,
      'mime_type': mimeType, 'size_bytes': sizeBytes, 'created_at': _now(),
    });
  }

  Future<List<Map<String, Object?>>> getIdeaAttachments(int ideaId) async {
    final db = await _database.database;
    return db.query('idea_attachments', where: 'idea_id = ?', whereArgs: [ideaId], orderBy: 'created_at DESC');
  }

  Future<void> deleteIdeaAttachment(int id) async {
    final db = await _database.database;
    await db.delete('idea_attachments', where: 'id = ?', whereArgs: [id]);
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

  Future<PerformanceData> getPerformanceData() async {
    final db = await _database.database;
    final counts = await db.rawQuery('''
      SELECT
        SUM(CASE WHEN is_archived = 0 THEN 1 ELSE 0 END) AS active_tasks,
        SUM(CASE WHEN is_archived = 0 AND is_complete = 1 THEN 1 ELSE 0 END) AS completed_tasks,
        SUM(CASE WHEN is_archived = 0 AND is_complete = 0 THEN 1 ELSE 0 END) AS open_tasks,
        SUM(CASE WHEN is_archived = 1 THEN 1 ELSE 0 END) AS archived_tasks
      FROM tasks
    ''');
    final row = counts.single;
    final historyRows = await db.query('task_completion_history', orderBy: 'occurred_at DESC, id DESC');
    return PerformanceData(
      activeTasks: (row['active_tasks'] as int?) ?? 0,
      completedTasks: (row['completed_tasks'] as int?) ?? 0,
      openTasks: (row['open_tasks'] as int?) ?? 0,
      archivedTasks: (row['archived_tasks'] as int?) ?? 0,
      activity: historyRows.map(TaskCompletionRecord.fromMap).toList(growable: false),
    );
  }
  Future<int> saveEvent({int? id, required String title, String notes = '', required DateTime startsAt, DateTime? endsAt, String? recurrenceRule, int reminderMinutes = 0}) async {
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
      'reminder_minutes': reminderMinutes,
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

  Future<List<Map<String, Object?>>> getEvents({bool includeArchived = false, DateTime? from, DateTime? to}) async {
    final db = await _database.database;
    final clauses = <String>[];
    final args = <Object?>[];
    if (!includeArchived) clauses.add('is_archived = 0');
    if (to != null) { clauses.add('starts_at <= ?'); args.add(to.millisecondsSinceEpoch); }
    if (from != null) {
      clauses.add('(starts_at >= ? OR (ends_at IS NOT NULL AND ends_at >= ?) OR recurrence_rule IS NOT NULL)');
      args..add(from.millisecondsSinceEpoch)..add(from.millisecondsSinceEpoch);
    }
    return db.query('events', where: clauses.isEmpty ? null : clauses.join(' AND '), whereArgs: args, orderBy: 'starts_at ASC');
  }

  Future<void> archiveEvent(int id, bool archived) async {
    final db = await _database.database;
    final changed = await db.update('events', {'is_archived': archived ? 1 : 0, 'updated_at': _now()}, where: 'id = ?', whereArgs: [id]);
    if (changed == 0) throw StateError('Event $id no longer exists.');
  }

  Future<void> deleteEvent(int id) async {
    final db = await _database.database;
    await db.delete('events', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<LifeTask>> getTasksDueBetween(DateTime from, DateTime to) async {
    final db = await _database.database;
    final rows = await db.query('tasks', where: 'is_archived = 0 AND due_at IS NOT NULL AND due_at >= ? AND due_at < ?', whereArgs: [from.millisecondsSinceEpoch, to.millisecondsSinceEpoch], orderBy: 'due_at ASC');
    return rows.map(LifeTask.fromMap).toList(growable: false);
  }
}
