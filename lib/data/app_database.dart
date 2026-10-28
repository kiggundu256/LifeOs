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
      version: 1,
      onConfigure: (db) async => db.execute('PRAGMA foreign_keys = ON'),
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE tasks (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT NOT NULL CHECK(length(trim(title)) > 0),
            notes TEXT NOT NULL DEFAULT '',
            is_complete INTEGER NOT NULL DEFAULT 0 CHECK(is_complete IN (0, 1)),
            is_archived INTEGER NOT NULL DEFAULT 0 CHECK(is_archived IN (0, 1)),
            due_at INTEGER,
            created_at INTEGER NOT NULL,
            updated_at INTEGER NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE ideas (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT NOT NULL CHECK(length(trim(title)) > 0),
            body TEXT NOT NULL DEFAULT '',
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
            is_archived INTEGER NOT NULL DEFAULT 0 CHECK(is_archived IN (0, 1)),
            created_at INTEGER NOT NULL,
            updated_at INTEGER NOT NULL,
            CHECK(ends_at IS NULL OR ends_at >= starts_at)
          )
        ''');
        await db.execute('CREATE INDEX idx_tasks_status ON tasks(is_complete, is_archived)');
        await db.execute('CREATE INDEX idx_ideas_archived ON ideas(is_archived)');
        await db.execute('CREATE INDEX idx_events_starts ON events(starts_at)');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        // Add future schema migrations here; never drop user data during upgrades.
      },
    );
    return _database!;
  }
}
