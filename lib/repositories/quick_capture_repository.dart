import 'package:sqflite/sqflite.dart';
import '../data/app_database.dart';
import '../models/quick_capture.dart';

class QuickCaptureRepository {
  QuickCaptureRepository({AppDatabase? database}) : _database=database??AppDatabase.instance;
  final AppDatabase _database;
  int _now()=>DateTime.now().millisecondsSinceEpoch;

  Future<int> capture({required String kind, required String title, String body='', DateTime? dueAt, DateTime? reminderAt, DateTime? scheduledAt, int reminderMinutes=0, int? projectId}) async {
    final clean=title.trim();
    if(clean.isEmpty) throw ArgumentError('Give your capture a title.');
    if(!const ['task','note','event'].contains(kind)) throw ArgumentError('Unsupported capture type.');
    if(kind=='task' && reminderAt!=null && dueAt!=null && reminderAt.isAfter(dueAt)) throw ArgumentError('A task reminder cannot be after its due date.');
    if(kind=='event' && scheduledAt==null) throw ArgumentError('Choose when the event starts.');
    final db=await _database.database; final now=_now();
    return db.insert('quick_captures', {'kind':kind,'title':clean,'body':body.trim(),'due_at':dueAt?.millisecondsSinceEpoch,'reminder_at':reminderAt?.millisecondsSinceEpoch,'scheduled_at':scheduledAt?.millisecondsSinceEpoch,'reminder_minutes':reminderMinutes,'project_id':projectId,'status':'inbox','created_at':now,'updated_at':now});
  }

  Future<List<QuickCapture>> getCaptures({String query='', String status='inbox', String? kind}) async {
    final db=await _database.database; final clauses=<String>['status = ?']; final args=<Object?>[status];
    if(kind!=null){clauses.add('kind = ?');args.add(kind);}
    if(query.trim().isNotEmpty){clauses.add('(title LIKE ? OR body LIKE ?)');final q='%${query.trim()}%';args..add(q)..add(q);}
    final rows=await db.query('quick_captures',where:clauses.join(' AND '),whereArgs:args,orderBy:'updated_at DESC,id DESC');
    return rows.map(QuickCapture.fromMap).toList(growable:false);
  }

  Future<void> updateCapture(int id,{required String title,required String body,DateTime? dueAt,DateTime? reminderAt,DateTime? scheduledAt,int reminderMinutes=0,int? projectId}) async {
    final clean=title.trim();if(clean.isEmpty)throw ArgumentError('Give your capture a title.');
    final db=await _database.database;final changed=await db.update('quick_captures',{'title':clean,'body':body.trim(),'due_at':dueAt?.millisecondsSinceEpoch,'reminder_at':reminderAt?.millisecondsSinceEpoch,'scheduled_at':scheduledAt?.millisecondsSinceEpoch,'reminder_minutes':reminderMinutes,'project_id':projectId,'updated_at':_now()},where:'id = ? AND status = ?',whereArgs:[id,'inbox']);
    if(changed==0)throw StateError('This capture is no longer in the inbox.');
  }

  Future<int> convertToTask(QuickCapture item) async {
    if(item.kind!='task')throw ArgumentError('Only task captures can become tasks.');
    final db=await _database.database;final now=_now();
    return db.transaction((txn) async {
      final current=await txn.query('quick_captures',where:'id = ? AND status = ?',whereArgs:[item.id,'inbox'],limit:1);
      if(current.isEmpty)throw StateError('This capture has already been processed.');
      final id=await txn.insert('tasks',{'title':item.title,'notes':item.body,'is_complete':0,'is_archived':0,'due_at':item.dueAt?.millisecondsSinceEpoch,'reminder_at':item.reminderAt?.millisecondsSinceEpoch,'project_id':item.projectId,'created_at':now,'updated_at':now});
      await txn.update('quick_captures',{'status':'processed','converted_type':'task','converted_id':id,'updated_at':now},where:'id = ?',whereArgs:[item.id]);return id;
    });
  }

  Future<int> convertToNote(QuickCapture item) async {
    if(item.kind!='note')throw ArgumentError('Only note captures can become notes.');
    final db=await _database.database;final now=_now();
    return db.transaction((txn) async {
      final current=await txn.query('quick_captures',where:'id = ? AND status = ?',whereArgs:[item.id,'inbox'],limit:1);
      if(current.isEmpty)throw StateError('This capture has already been processed.');
      final id=await txn.insert('ideas',{'title':item.title,'body':item.body,'is_pinned':0,'is_archived':0,'created_at':now,'updated_at':now});
      await txn.update('quick_captures',{'status':'processed','converted_type':'note','converted_id':id,'updated_at':now},where:'id = ?',whereArgs:[item.id]);return id;
    });
  }

  Future<int> convertToEvent(QuickCapture item) async {
    if(item.kind!='event'||item.scheduledAt==null)throw ArgumentError('This capture is not a scheduled event.');
    final db=await _database.database;final now=_now();
    return db.transaction((txn) async {
      final current=await txn.query('quick_captures',where:'id = ? AND status = ?',whereArgs:[item.id,'inbox'],limit:1);
      if(current.isEmpty)throw StateError('This capture has already been processed.');
      final id=await txn.insert('events',{'title':item.title,'notes':item.body,'starts_at':item.scheduledAt!.millisecondsSinceEpoch,'ends_at':null,'recurrence_rule':null,'reminder_minutes':item.reminderMinutes,'is_archived':0,'created_at':now,'updated_at':now});
      await txn.update('quick_captures',{'status':'processed','converted_type':'event','converted_id':id,'updated_at':now},where:'id = ?',whereArgs:[item.id]);return id;
    });
  }

  Future<void> setStatus(int id,String status) async {if(!const ['inbox','archived'].contains(status))throw ArgumentError('Invalid capture status.');final db=await _database.database;final n=await db.update('quick_captures',{'status':status,'updated_at':_now()},where:'id = ? AND status != ?',whereArgs:[id,'processed']);if(n==0)throw StateError('Processed captures cannot be moved back to the inbox.');}
  Future<void> deleteCapture(int id) async {final db=await _database.database;await db.delete('quick_captures',where:'id = ?',whereArgs:[id]);}
}
