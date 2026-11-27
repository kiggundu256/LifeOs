import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

class AppDatabase {
  AppDatabase._();
  static final AppDatabase instance = AppDatabase._();

  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    final dbPath = await getDatabasesPath();
    _database = await openDatabase(
      p.join(dbPath, 'lifeos.db'),
      version: 7,
      onConfigure: (db) async => db.execute('PRAGMA foreign_keys = ON'),
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE projects (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT NOT NULL CHECK(length(trim(title)) > 0),
            description TEXT NOT NULL DEFAULT '',
            objective TEXT NOT NULL DEFAULT '',
            priority TEXT NOT NULL DEFAULT 'medium' CHECK(priority IN ('low','medium','high')),
            status TEXT NOT NULL DEFAULT 'active' CHECK(status IN ('active','on_hold','completed')),
            start_at INTEGER,
            due_at INTEGER,
            is_archived INTEGER NOT NULL DEFAULT 0 CHECK(is_archived IN (0,1)),
            created_at INTEGER NOT NULL,
            updated_at INTEGER NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE tasks (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT NOT NULL CHECK(length(trim(title)) > 0),
            notes TEXT NOT NULL DEFAULT '',
            is_complete INTEGER NOT NULL DEFAULT 0 CHECK(is_complete IN (0, 1)),
            is_archived INTEGER NOT NULL DEFAULT 0 CHECK(is_archived IN (0, 1)),
            due_at INTEGER,
            reminder_at INTEGER,
            project_id INTEGER REFERENCES projects(id) ON DELETE SET NULL,
            created_at INTEGER NOT NULL,
            updated_at INTEGER NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE brain_folders (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL COLLATE NOCASE UNIQUE CHECK(length(trim(name)) > 0),
            color INTEGER NOT NULL DEFAULT 0,
            created_at INTEGER NOT NULL,
            updated_at INTEGER NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE ideas (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT NOT NULL CHECK(length(trim(title)) > 0),
            body TEXT NOT NULL DEFAULT '',
            is_pinned INTEGER NOT NULL DEFAULT 0 CHECK(is_pinned IN (0, 1)),
            folder_id INTEGER REFERENCES brain_folders(id) ON DELETE SET NULL,
            is_archived INTEGER NOT NULL DEFAULT 0 CHECK(is_archived IN (0, 1)),
            created_at INTEGER NOT NULL,
            updated_at INTEGER NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE events (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT NOT NULL CHECK(length(trim(title)) > 0),
            notes TEXT NOT NULL DEFAULT '',
            starts_at INTEGER NOT NULL,
            ends_at INTEGER,
            recurrence_rule TEXT,
            reminder_minutes INTEGER NOT NULL DEFAULT 0,
            is_archived INTEGER NOT NULL DEFAULT 0 CHECK(is_archived IN (0, 1)),
            created_at INTEGER NOT NULL,
            updated_at INTEGER NOT NULL,
            CHECK(ends_at IS NULL OR ends_at >= starts_at)
          )
        ''');
        await db.execute('CREATE INDEX idx_tasks_status ON tasks(is_complete, is_archived)');
        await db.execute('CREATE INDEX idx_tasks_project ON tasks(project_id, is_archived, is_complete)');
        await db.execute('''CREATE TABLE project_milestones (id INTEGER PRIMARY KEY AUTOINCREMENT, project_id INTEGER NOT NULL REFERENCES projects(id) ON DELETE CASCADE, title TEXT NOT NULL CHECK(length(trim(title)) > 0), due_at INTEGER, is_complete INTEGER NOT NULL DEFAULT 0 CHECK(is_complete IN (0,1)), created_at INTEGER NOT NULL, updated_at INTEGER NOT NULL)''');
        await db.execute('CREATE INDEX idx_project_milestones_project ON project_milestones(project_id, is_complete)');
        await db.execute('''CREATE TABLE project_notes (project_id INTEGER PRIMARY KEY REFERENCES projects(id) ON DELETE CASCADE, body TEXT NOT NULL DEFAULT '', updated_at INTEGER NOT NULL)''');
        await db.execute('''CREATE TABLE project_attachments (id INTEGER PRIMARY KEY AUTOINCREMENT, project_id INTEGER NOT NULL REFERENCES projects(id) ON DELETE CASCADE, display_name TEXT NOT NULL, stored_path TEXT NOT NULL, mime_type TEXT, size_bytes INTEGER NOT NULL DEFAULT 0, created_at INTEGER NOT NULL)''');
        await db.execute('CREATE INDEX idx_project_attachments_project ON project_attachments(project_id)');
        await db.execute('CREATE INDEX idx_ideas_archived ON ideas(is_archived)');
        await db.execute('CREATE INDEX idx_ideas_pinned ON ideas(is_pinned, updated_at)');
        await db.execute('''
          CREATE TABLE brain_tags (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL COLLATE NOCASE UNIQUE CHECK(length(trim(name)) > 0),
            created_at INTEGER NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE idea_tags (
            idea_id INTEGER NOT NULL REFERENCES ideas(id) ON DELETE CASCADE,
            tag_id INTEGER NOT NULL REFERENCES brain_tags(id) ON DELETE CASCADE,
            PRIMARY KEY (idea_id, tag_id)
          )
        ''');
        await db.execute('CREATE INDEX idx_idea_tags_tag ON idea_tags(tag_id)');
        await db.execute('''
          CREATE TABLE idea_attachments (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            idea_id INTEGER NOT NULL REFERENCES ideas(id) ON DELETE CASCADE,
            display_name TEXT NOT NULL,
            stored_path TEXT NOT NULL,
            mime_type TEXT,
            size_bytes INTEGER NOT NULL DEFAULT 0,
            created_at INTEGER NOT NULL
          )
        ''');
        await db.execute('CREATE INDEX idx_idea_attachments_idea ON idea_attachments(idea_id)');
        await db.execute('CREATE INDEX idx_events_starts ON events(starts_at)');
        await db.execute('CREATE INDEX idx_tasks_due ON tasks(due_at)');
        await db.execute('''
          CREATE TABLE task_completion_history (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            task_id INTEGER NOT NULL,
            task_title TEXT NOT NULL,
            action TEXT NOT NULL CHECK(action IN ('completed', 'reopened')),
            occurred_at INTEGER NOT NULL
          )
        ''');
        await db.execute('CREATE INDEX idx_task_completion_history_date ON task_completion_history(occurred_at)');
        await db.execute('''
          CREATE TABLE quick_captures (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            kind TEXT NOT NULL CHECK(kind IN ('task','note','event')),
            title TEXT NOT NULL CHECK(length(trim(title)) > 0),
            body TEXT NOT NULL DEFAULT '',
            due_at INTEGER,
            reminder_at INTEGER,
            scheduled_at INTEGER,
            reminder_minutes INTEGER NOT NULL DEFAULT 0,
            project_id INTEGER REFERENCES projects(id) ON DELETE SET NULL,
            status TEXT NOT NULL DEFAULT 'inbox' CHECK(status IN ('inbox','processed','archived')),
            converted_type TEXT,
            converted_id INTEGER,
            created_at INTEGER NOT NULL,
            updated_at INTEGER NOT NULL
          )
        ''');
        await db.execute('CREATE INDEX idx_quick_captures_status ON quick_captures(status, updated_at DESC)');
        await db.execute('CREATE INDEX idx_quick_captures_project ON quick_captures(project_id)');
        await db.execute('''
          CREATE TABLE focus_sessions (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            started_at INTEGER NOT NULL,
            ended_at INTEGER NOT NULL,
            planned_minutes INTEGER NOT NULL CHECK(planned_minutes > 0),
            focused_seconds INTEGER NOT NULL CHECK(focused_seconds >= 0),
            status TEXT NOT NULL CHECK(status IN ('completed','stopped'))
          )
        ''');
        await db.execute('CREATE INDEX idx_focus_sessions_started ON focus_sessions(started_at DESC)');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('''
          CREATE TABLE task_completion_history (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            task_id INTEGER NOT NULL,
            task_title TEXT NOT NULL,
            action TEXT NOT NULL CHECK(action IN ('completed', 'reopened')),
            occurred_at INTEGER NOT NULL
          )
          ''');
          await db.execute('CREATE INDEX idx_task_completion_history_date ON task_completion_history(occurred_at)');
        }
        if (oldVersion < 4) {
          await db.execute('''
            CREATE TABLE brain_folders (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              name TEXT NOT NULL COLLATE NOCASE UNIQUE CHECK(length(trim(name)) > 0),
              color INTEGER NOT NULL DEFAULT 0,
              created_at INTEGER NOT NULL,
              updated_at INTEGER NOT NULL
            )
          ''');
          await db.execute('ALTER TABLE ideas ADD COLUMN is_pinned INTEGER NOT NULL DEFAULT 0');
          await db.execute('ALTER TABLE ideas ADD COLUMN folder_id INTEGER REFERENCES brain_folders(id) ON DELETE SET NULL');
          await db.execute('''
            CREATE TABLE brain_tags (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              name TEXT NOT NULL COLLATE NOCASE UNIQUE CHECK(length(trim(name)) > 0),
              created_at INTEGER NOT NULL
            )
          ''');
          await db.execute('''
            CREATE TABLE idea_tags (
              idea_id INTEGER NOT NULL REFERENCES ideas(id) ON DELETE CASCADE,
              tag_id INTEGER NOT NULL REFERENCES brain_tags(id) ON DELETE CASCADE,
              PRIMARY KEY (idea_id, tag_id)
            )
          ''');
          await db.execute('CREATE INDEX idx_idea_tags_tag ON idea_tags(tag_id)');
          await db.execute('''
            CREATE TABLE idea_attachments (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              idea_id INTEGER NOT NULL REFERENCES ideas(id) ON DELETE CASCADE,
              display_name TEXT NOT NULL,
              stored_path TEXT NOT NULL,
              mime_type TEXT,
              size_bytes INTEGER NOT NULL DEFAULT 0,
              created_at INTEGER NOT NULL
            )
          ''');
          await db.execute('CREATE INDEX idx_idea_attachments_idea ON idea_attachments(idea_id)');
          await db.execute('CREATE INDEX idx_ideas_pinned ON ideas(is_pinned, updated_at)');
        }
        if (oldVersion < 3) {
          await db.execute('ALTER TABLE tasks ADD COLUMN reminder_at INTEGER');
          await db.execute('ALTER TABLE events ADD COLUMN reminder_minutes INTEGER NOT NULL DEFAULT 0');
          await db.execute('CREATE INDEX idx_tasks_due ON tasks(due_at)');
        }
        if (oldVersion < 5) {
          await db.execute('''CREATE TABLE projects (id INTEGER PRIMARY KEY AUTOINCREMENT, title TEXT NOT NULL CHECK(length(trim(title)) > 0), description TEXT NOT NULL DEFAULT '', objective TEXT NOT NULL DEFAULT '', priority TEXT NOT NULL DEFAULT 'medium' CHECK(priority IN ('low','medium','high')), status TEXT NOT NULL DEFAULT 'active' CHECK(status IN ('active','on_hold','completed')), start_at INTEGER, due_at INTEGER, is_archived INTEGER NOT NULL DEFAULT 0 CHECK(is_archived IN (0,1)), created_at INTEGER NOT NULL, updated_at INTEGER NOT NULL)''');
          await db.execute('ALTER TABLE tasks ADD COLUMN project_id INTEGER REFERENCES projects(id) ON DELETE SET NULL');
          await db.execute('CREATE INDEX idx_tasks_project ON tasks(project_id, is_archived, is_complete)');
          await db.execute('''CREATE TABLE project_milestones (id INTEGER PRIMARY KEY AUTOINCREMENT, project_id INTEGER NOT NULL REFERENCES projects(id) ON DELETE CASCADE, title TEXT NOT NULL CHECK(length(trim(title)) > 0), due_at INTEGER, is_complete INTEGER NOT NULL DEFAULT 0 CHECK(is_complete IN (0,1)), created_at INTEGER NOT NULL, updated_at INTEGER NOT NULL)''');
          await db.execute('CREATE INDEX idx_project_milestones_project ON project_milestones(project_id, is_complete)');
          await db.execute('''CREATE TABLE project_notes (project_id INTEGER PRIMARY KEY REFERENCES projects(id) ON DELETE CASCADE, body TEXT NOT NULL DEFAULT '', updated_at INTEGER NOT NULL)''');
          await db.execute('''CREATE TABLE project_attachments (id INTEGER PRIMARY KEY AUTOINCREMENT, project_id INTEGER NOT NULL REFERENCES projects(id) ON DELETE CASCADE, display_name TEXT NOT NULL, stored_path TEXT NOT NULL, mime_type TEXT, size_bytes INTEGER NOT NULL DEFAULT 0, created_at INTEGER NOT NULL)''');
          await db.execute('CREATE INDEX idx_project_attachments_project ON project_attachments(project_id)');
        }
        if (oldVersion < 6) {
          await db.execute('''
            CREATE TABLE quick_captures (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              kind TEXT NOT NULL CHECK(kind IN ('task','note','event')),
              title TEXT NOT NULL CHECK(length(trim(title)) > 0),
              body TEXT NOT NULL DEFAULT '',
              due_at INTEGER,
              reminder_at INTEGER,
              scheduled_at INTEGER,
              reminder_minutes INTEGER NOT NULL DEFAULT 0,
              project_id INTEGER REFERENCES projects(id) ON DELETE SET NULL,
              status TEXT NOT NULL DEFAULT 'inbox' CHECK(status IN ('inbox','processed','archived')),
              converted_type TEXT,
              converted_id INTEGER,
              created_at INTEGER NOT NULL,
              updated_at INTEGER NOT NULL
            )
          ''');
          await db.execute('CREATE INDEX idx_quick_captures_status ON quick_captures(status, updated_at DESC)');
          await db.execute('CREATE INDEX idx_quick_captures_project ON quick_captures(project_id)');
        }
        if (oldVersion < 7) {
          await db.execute('''CREATE TABLE focus_sessions (id INTEGER PRIMARY KEY AUTOINCREMENT, started_at INTEGER NOT NULL, ended_at INTEGER NOT NULL, planned_minutes INTEGER NOT NULL CHECK(planned_minutes > 0), focused_seconds INTEGER NOT NULL CHECK(focused_seconds >= 0), status TEXT NOT NULL CHECK(status IN ('completed','stopped')))''');
          await db.execute('CREATE INDEX idx_focus_sessions_started ON focus_sessions(started_at DESC)');
        }
      },
    );
    return _database!;
  }
}
