import 'package:sqflite/sqflite.dart';

class LocalDatabase {
  static final LocalDatabase _instance = LocalDatabase._internal();

  Database? _db;

  LocalDatabase._internal();

  factory LocalDatabase() {
    return _instance;
  }

  Future<Database> get database async {
    _db ??= await _initDatabase();
    return _db!;
  }

  Future<void> initialize() async {
    await database; // Trigger initialization
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final dbFilePath = '$dbPath/likha.db';

    return openDatabase(
      dbFilePath,
      version: 2,
      onCreate: _createTables,
      onUpgrade: _upgradeDatabase,
      onOpen: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
    );
  }

  Future<void> _createTables(Database db, int version) async {
    await db.transaction((txn) async {
      // Users table
      await txn.execute('''
        CREATE TABLE IF NOT EXISTS users (
          id TEXT PRIMARY KEY,
          username TEXT NOT NULL UNIQUE,
          full_name TEXT NOT NULL,
          role TEXT NOT NULL,
          account_status TEXT NOT NULL,
          is_active INTEGER NOT NULL DEFAULT 1,
          activated_at TEXT,
          created_at TEXT NOT NULL,
          cached_at TEXT NOT NULL,
          is_dirty INTEGER NOT NULL DEFAULT 0,
          sync_status TEXT NOT NULL DEFAULT 'synced'
        )
      ''');

      // Classes table
      await txn.execute('''
        CREATE TABLE IF NOT EXISTS classes (
          id TEXT PRIMARY KEY,
          title TEXT NOT NULL,
          description TEXT,
          teacher_id TEXT NOT NULL,
          teacher_username TEXT NOT NULL,
          teacher_full_name TEXT NOT NULL,
          is_archived INTEGER NOT NULL DEFAULT 0,
          student_count INTEGER NOT NULL DEFAULT 0,
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL,
          cached_at TEXT NOT NULL,
          is_dirty INTEGER NOT NULL DEFAULT 0,
          sync_status TEXT NOT NULL DEFAULT 'synced'
        )
      ''');

      // Class enrollments table
      await txn.execute('''
        CREATE TABLE IF NOT EXISTS class_enrollments (
          id TEXT PRIMARY KEY,
          class_id TEXT NOT NULL,
          student_id TEXT NOT NULL,
          username TEXT NOT NULL,
          full_name TEXT NOT NULL,
          role TEXT NOT NULL,
          account_status TEXT NOT NULL,
          is_active INTEGER NOT NULL DEFAULT 1,
          enrolled_at TEXT NOT NULL,
          cached_at TEXT NOT NULL,
          FOREIGN KEY(class_id) REFERENCES classes(id) ON DELETE CASCADE
        )
      ''');

      // Assessments table
      await txn.execute('''
        CREATE TABLE IF NOT EXISTS assessments (
          id TEXT PRIMARY KEY,
          class_id TEXT NOT NULL,
          title TEXT NOT NULL,
          description TEXT,
          time_limit_minutes INTEGER NOT NULL,
          open_at TEXT NOT NULL,
          close_at TEXT NOT NULL,
          show_results_immediately INTEGER NOT NULL DEFAULT 0,
          results_released INTEGER NOT NULL DEFAULT 0,
          is_published INTEGER NOT NULL DEFAULT 0,
          total_points INTEGER NOT NULL DEFAULT 0,
          question_count INTEGER NOT NULL DEFAULT 0,
          submission_count INTEGER NOT NULL DEFAULT 0,
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL,
          cached_at TEXT NOT NULL,
          is_dirty INTEGER NOT NULL DEFAULT 0,
          sync_status TEXT NOT NULL DEFAULT 'synced',
          FOREIGN KEY(class_id) REFERENCES classes(id) ON DELETE CASCADE
        )
      ''');

      // Questions table
      await txn.execute('''
        CREATE TABLE IF NOT EXISTS questions (
          id TEXT PRIMARY KEY,
          assessment_id TEXT NOT NULL,
          question_type TEXT NOT NULL,
          question_text TEXT NOT NULL,
          points INTEGER NOT NULL,
          order_index INTEGER NOT NULL,
          is_multi_select INTEGER NOT NULL DEFAULT 0,
          choices_json TEXT,
          correct_answers_json TEXT,
          enumeration_items_json TEXT,
          cached_at TEXT NOT NULL,
          FOREIGN KEY(assessment_id) REFERENCES assessments(id) ON DELETE CASCADE
        )
      ''');

      // Assessment submissions table
      await txn.execute('''
        CREATE TABLE IF NOT EXISTS assessment_submissions (
          id TEXT PRIMARY KEY,
          assessment_id TEXT NOT NULL,
          student_id TEXT NOT NULL,
          student_name TEXT NOT NULL,
          student_username TEXT NOT NULL,
          started_at TEXT NOT NULL,
          submitted_at TEXT,
          auto_score INTEGER,
          final_score INTEGER,
          is_submitted INTEGER NOT NULL DEFAULT 0,
          answers_json TEXT,
          local_start_at TEXT,
          cached_at TEXT NOT NULL,
          is_dirty INTEGER NOT NULL DEFAULT 0,
          sync_status TEXT NOT NULL DEFAULT 'synced',
          FOREIGN KEY(assessment_id) REFERENCES assessments(id) ON DELETE CASCADE
        )
      ''');

      // Assignments table
      await txn.execute('''
        CREATE TABLE IF NOT EXISTS assignments (
          id TEXT PRIMARY KEY,
          class_id TEXT NOT NULL,
          title TEXT NOT NULL,
          instructions TEXT,
          total_points INTEGER NOT NULL DEFAULT 0,
          submission_type TEXT NOT NULL,
          allowed_file_types TEXT,
          max_file_size_mb INTEGER,
          due_at TEXT,
          is_published INTEGER NOT NULL DEFAULT 0,
          submission_count INTEGER NOT NULL DEFAULT 0,
          graded_count INTEGER NOT NULL DEFAULT 0,
          submission_status TEXT,
          submission_id TEXT,
          score INTEGER,
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL,
          cached_at TEXT NOT NULL,
          is_dirty INTEGER NOT NULL DEFAULT 0,
          sync_status TEXT NOT NULL DEFAULT 'synced',
          FOREIGN KEY(class_id) REFERENCES classes(id) ON DELETE CASCADE
        )
      ''');

      // Assignment submissions table
      await txn.execute('''
        CREATE TABLE IF NOT EXISTS assignment_submissions (
          id TEXT PRIMARY KEY,
          assignment_id TEXT NOT NULL,
          student_id TEXT NOT NULL,
          student_name TEXT NOT NULL,
          status TEXT NOT NULL,
          text_content TEXT,
          submitted_at TEXT,
          is_late INTEGER NOT NULL DEFAULT 0,
          score INTEGER,
          feedback TEXT,
          graded_at TEXT,
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL,
          cached_at TEXT NOT NULL,
          is_dirty INTEGER NOT NULL DEFAULT 0,
          sync_status TEXT NOT NULL DEFAULT 'synced',
          FOREIGN KEY(assignment_id) REFERENCES assignments(id) ON DELETE CASCADE
        )
      ''');

      // Submission files table
      await txn.execute('''
        CREATE TABLE IF NOT EXISTS submission_files (
          id TEXT PRIMARY KEY,
          submission_id TEXT NOT NULL,
          file_name TEXT NOT NULL,
          file_type TEXT NOT NULL,
          file_size INTEGER NOT NULL,
          uploaded_at TEXT NOT NULL,
          local_path TEXT,
          is_local_only INTEGER NOT NULL DEFAULT 0,
          cached_at TEXT NOT NULL,
          FOREIGN KEY(submission_id) REFERENCES assignment_submissions(id) ON DELETE CASCADE
        )
      ''');

      // Learning materials table
      await txn.execute('''
        CREATE TABLE IF NOT EXISTS learning_materials (
          id TEXT PRIMARY KEY,
          class_id TEXT NOT NULL,
          title TEXT NOT NULL,
          description TEXT,
          content_text TEXT,
          order_index INTEGER NOT NULL DEFAULT 0,
          file_count INTEGER NOT NULL DEFAULT 0,
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL,
          cached_at TEXT NOT NULL,
          is_dirty INTEGER NOT NULL DEFAULT 0,
          sync_status TEXT NOT NULL DEFAULT 'synced',
          FOREIGN KEY(class_id) REFERENCES classes(id) ON DELETE CASCADE
        )
      ''');

      // Material files table
      await txn.execute('''
        CREATE TABLE IF NOT EXISTS material_files (
          id TEXT PRIMARY KEY,
          material_id TEXT NOT NULL,
          file_name TEXT NOT NULL,
          file_type TEXT NOT NULL,
          file_size INTEGER NOT NULL,
          uploaded_at TEXT NOT NULL,
          local_path TEXT,
          is_cached INTEGER NOT NULL DEFAULT 0,
          cached_at TEXT NOT NULL,
          FOREIGN KEY(material_id) REFERENCES learning_materials(id) ON DELETE CASCADE
        )
      ''');

      // Validation metadata table
      await txn.execute('''
        CREATE TABLE IF NOT EXISTS validation_metadata (
          entity_type TEXT PRIMARY KEY,
          last_modified TEXT NOT NULL,
          record_count INTEGER NOT NULL,
          etag TEXT,
          validated_at TEXT NOT NULL,
          database_id TEXT
        )
      ''');

      // Sync queue table
      await txn.execute('''
        CREATE TABLE IF NOT EXISTS sync_queue (
          id TEXT PRIMARY KEY,
          entity_type TEXT NOT NULL,
          operation TEXT NOT NULL,
          payload TEXT NOT NULL,
          status TEXT NOT NULL,
          retry_count INTEGER NOT NULL DEFAULT 0,
          max_retries INTEGER NOT NULL DEFAULT 5,
          created_at TEXT NOT NULL,
          last_attempted_at TEXT,
          error_message TEXT
        )
      ''');

      // Sync metadata table (stores last synced sequence)
      await txn.execute('''
        CREATE TABLE IF NOT EXISTS sync_metadata (
          key TEXT PRIMARY KEY,
          value TEXT NOT NULL
        )
      ''');

      // Create indexes for common queries
      await txn.execute('CREATE INDEX IF NOT EXISTS idx_classes_teacher_id ON classes(teacher_id)');
      await txn.execute('CREATE INDEX IF NOT EXISTS idx_class_enrollments_class_id ON class_enrollments(class_id)');
      await txn.execute('CREATE INDEX IF NOT EXISTS idx_assessments_class_id ON assessments(class_id)');
      await txn.execute('CREATE INDEX IF NOT EXISTS idx_questions_assessment_id ON questions(assessment_id)');
      await txn.execute('CREATE INDEX IF NOT EXISTS idx_assessment_submissions_assessment_id ON assessment_submissions(assessment_id)');
      await txn.execute('CREATE INDEX IF NOT EXISTS idx_assignments_class_id ON assignments(class_id)');
      await txn.execute('CREATE INDEX IF NOT EXISTS idx_assignment_submissions_assignment_id ON assignment_submissions(assignment_id)');
      await txn.execute('CREATE INDEX IF NOT EXISTS idx_submission_files_submission_id ON submission_files(submission_id)');
      await txn.execute('CREATE INDEX IF NOT EXISTS idx_learning_materials_class_id ON learning_materials(class_id)');
      await txn.execute('CREATE INDEX IF NOT EXISTS idx_material_files_material_id ON material_files(material_id)');
      await txn.execute('CREATE INDEX IF NOT EXISTS idx_sync_queue_status ON sync_queue(status)');
      await txn.execute('CREATE INDEX IF NOT EXISTS idx_sync_queue_created_at ON sync_queue(created_at)');
      await txn.execute('CREATE INDEX IF NOT EXISTS idx_sync_metadata_key ON sync_metadata(key)');
    });
  }

  Future<void> _upgradeDatabase(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Create validation_metadata table if it doesn't exist
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

      // Try to add database_id column in case table already exists from old schema
      try {
        await db.execute('''
          ALTER TABLE validation_metadata ADD COLUMN database_id TEXT
        ''');
      } catch (e) {
        // Column already exists, that's fine
      }
    }
  }

  Future<void> close() async {
    if (_db != null) {
      await _db!.close();
      _db = null;
    }
  }
}
