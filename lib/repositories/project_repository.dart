import 'package:sqflite/sqflite.dart';
import '../data/app_database.dart';
import '../models/life_project.dart';

class ProjectRepository {
  ProjectRepository({AppDatabase? database}) : _database = database ?? AppDatabase.instance;
  final AppDatabase _database;
  int _now() => DateTime.now().millisecondsSinceEpoch;

  Future<List<Map<String,Object?>>> getProjects({String query = '', bool includeArchived = false}) async {
    final db = await _database.database;
    final clauses = <String>[];
    final args = <Object?>[];
    clauses.add('p.is_archived = ?'); args.add(includeArchived ? 1 : 0);
    if (query.trim().isNotEmpty) {
      clauses.add('(p.title LIKE ? OR p.description LIKE ? OR p.objective LIKE ?)');
      final q = '%${query.trim()}%'; args..add(q)..add(q)..add(q);
    }
    return db.rawQuery('''
      SELECT p.*,
        (SELECT COUNT(*) FROM tasks t WHERE t.project_id=p.id AND t.is_archived=0) AS task_count,
        (SELECT COUNT(*) FROM tasks t WHERE t.project_id=p.id AND t.is_archived=0 AND t.is_complete=1) AS completed_tasks,
        (SELECT COUNT(*) FROM project_milestones m WHERE m.project_id=p.id) AS milestone_count,
        (SELECT COUNT(*) FROM project_milestones m WHERE m.project_id=p.id AND m.is_complete=1) AS completed_milestones
      FROM projects p WHERE ${clauses.join(' AND ')}
      ORDER BY CASE p.status WHEN 'active' THEN 0 WHEN 'on_hold' THEN 1 WHEN 'completed' THEN 2 ELSE 3 END,
      CASE p.priority WHEN 'high' THEN 0 WHEN 'medium' THEN 1 ELSE 2 END, p.updated_at DESC
    ''', args);
  }

  Future<int> saveProject({int? id, required String title, String description='', String objective='', String priority='medium', String status='active', DateTime? startAt, DateTime? dueAt}) async {
    final clean = title.trim();
    if (clean.isEmpty) throw ArgumentError('Project name cannot be empty.');
    if (dueAt != null && startAt != null && dueAt.isBefore(startAt)) throw ArgumentError('Deadline cannot be before the start date.');
    final db = await _database.database; final now = _now();
    final values = <String,Object?>{'title':clean,'description':description.trim(),'objective':objective.trim(),'priority':priority,'status':status,'start_at':startAt?.millisecondsSinceEpoch,'due_at':dueAt?.millisecondsSinceEpoch,'updated_at':now};
    if (id == null) { values.addAll({'is_archived':0,'created_at':now}); return db.insert('projects',values); }
    final count = await db.update('projects',values,where:'id = ?',whereArgs:[id]);
    if (count == 0) throw StateError('Project $id no longer exists.');
    return id;
  }

  Future<void> archiveProject(int id, bool archived) async {
    final db=await _database.database;
    final count=await db.update('projects',{'is_archived':archived?1:0,'updated_at':_now()},where:'id = ?',whereArgs:[id]);
    if(count==0) throw StateError('Project $id no longer exists.');
  }
  Future<void> deleteProject(int id) async { final db=await _database.database; await db.delete('projects',where:'id = ?',whereArgs:[id]); }

  Future<List<Map<String,Object?>>> getTasks(int projectId) async {
    final db=await _database.database;
    return db.query('tasks',where:'project_id = ? AND is_archived = 0',whereArgs:[projectId],orderBy:'is_complete ASC, due_at IS NULL ASC, due_at ASC, updated_at DESC');
  }
  Future<int> addTask({required int projectId,required String title,String notes='',DateTime? dueAt}) async {
    final clean=title.trim(); if(clean.isEmpty) throw ArgumentError('Task title cannot be empty.');
    final db=await _database.database; final now=_now();
    return db.insert('tasks',{'title':clean,'notes':notes.trim(),'project_id':projectId,'is_complete':0,'is_archived':0,'due_at':dueAt?.millisecondsSinceEpoch,'created_at':now,'updated_at':now});
  }
  Future<void> setTaskComplete(int id,bool complete) async {
    final db=await _database.database;
    await db.update('tasks',{'is_complete':complete?1:0,'updated_at':_now()},where:'id = ?',whereArgs:[id]);
  }

  Future<List<Map<String,Object?>>> getMilestones(int projectId) async {
    final db=await _database.database;
    return db.query('project_milestones',where:'project_id = ?',whereArgs:[projectId],orderBy:'is_complete ASC, due_at IS NULL ASC, due_at ASC, id ASC');
  }
  Future<int> addMilestone({required int projectId,required String title,DateTime? dueAt}) async {
    final clean=title.trim(); if(clean.isEmpty) throw ArgumentError('Milestone name cannot be empty.');
    final db=await _database.database; final now=_now();
    return db.insert('project_milestones',{'project_id':projectId,'title':clean,'due_at':dueAt?.millisecondsSinceEpoch,'is_complete':0,'created_at':now,'updated_at':now});
  }
  Future<void> setMilestoneComplete(int id,bool complete) async {
    final db=await _database.database;
    await db.update('project_milestones',{'is_complete':complete?1:0,'updated_at':_now()},where:'id = ?',whereArgs:[id]);
  }
  Future<void> deleteMilestone(int id) async { final db=await _database.database; await db.delete('project_milestones',where:'id = ?',whereArgs:[id]); }

  Future<String> getProjectNotes(int projectId) async {
    final db=await _database.database;
    final rows=await db.query('project_notes',columns:['body'],where:'project_id = ?',whereArgs:[projectId],limit:1);
    return rows.isEmpty ? '' : rows.single['body'] as String;
  }
  Future<void> saveProjectNotes(int projectId,String body) async {
    final db=await _database.database; final now=_now();
    await db.insert('project_notes',{'project_id':projectId,'body':body,'updated_at':now},conflictAlgorithm:ConflictAlgorithm.replace);
  }
}
