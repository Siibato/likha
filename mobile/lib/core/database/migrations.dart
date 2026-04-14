import 'package:sqflite/sqflite.dart';

/// Represents a database migration
class Migration {
  final int version;
  final String description;
  final Future<void> Function(Database db) up;

  const Migration({
    required this.version,
    required this.description,
    required this.up,
  });
}

/// Migration runner for executing pending database migrations
class MigrationRunner {
  static const String _migrationsTable = 'schema_migrations';
  
  /// Initialize the migrations tracking table
  static Future<void> _initMigrationsTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $_migrationsTable (
        version INTEGER PRIMARY KEY,
        description TEXT NOT NULL,
        applied_at TEXT NOT NULL
      )
    ''');
  }
  
  /// Get the last applied migration version
  static Future<int> _getLastAppliedVersion(Database db) async {
    final result = await db.query(
      _migrationsTable,
      orderBy: 'version DESC',
      limit: 1,
    );
    if (result.isEmpty) return 0;
    return result.first['version'] as int;
  }
  
  /// Record a migration as applied
  static Future<void> _recordMigration(Database db, Migration migration) async {
    await db.insert(
      _migrationsTable,
      {
        'version': migration.version,
        'description': migration.description,
        'applied_at': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
  
  /// Run all pending migrations
  static Future<void> runMigrations(Database db, List<Migration> migrations) async {
    await _initMigrationsTable(db);
    
    final lastApplied = await _getLastAppliedVersion(db);
    final pending = migrations.where((m) => m.version > lastApplied).toList();
    
    if (pending.isEmpty) return;
    
    // Sort by version and apply in order
    pending.sort((a, b) => a.version.compareTo(b.version));
    
    for (final migration in pending) {
      await db.transaction((txn) async {
        await migration.up(db);
        await _recordMigration(db, migration);
      });
    }
  }
  
  /// Define all migrations for the application
  static List<Migration> get allMigrations => [
    Migration(
      version: 12,
      description: 'Add validation_metadata table',
      up: (db) async {
        await db.execute('''
          CREATE TABLE IF NOT EXISTS validation_metadata (
            entity_type TEXT PRIMARY KEY,
            last_modified TEXT NOT NULL,
            record_count INTEGER NOT NULL,
            etag TEXT,
            validated_at TEXT NOT NULL,
            database_id TEXT
          )
        ''');
      },
    ),
  ];
}
