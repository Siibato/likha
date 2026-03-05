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
      version: 12,
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
          activated_at TEXT,
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL,
          deleted_at TEXT,
          cached_at TEXT NOT NULL,
          is_offline_mutation INTEGER NOT NULL DEFAULT 0,
          sync_status TEXT NOT NULL DEFAULT 'synced'
        )
      ''');

      // Classes table
      await txn.execute('''
        CREATE TABLE IF NOT EXISTS classes (
          id TEXT PRIMARY KEY,
          local_id TEXT,
          title TEXT NOT NULL,
          description TEXT,
          teacher_id TEXT NOT NULL,
          teacher_username TEXT NOT NULL,
          teacher_full_name TEXT NOT NULL,
          is_archived INTEGER NOT NULL DEFAULT 0,
          student_count INTEGER NOT NULL DEFAULT 0,
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL,
          deleted_at TEXT,
          cached_at TEXT NOT NULL,
          synced_at TEXT,
          is_offline_mutation INTEGER NOT NULL DEFAULT 0,
          sync_status TEXT NOT NULL DEFAULT 'synced'
        )
      ''');

      // Class participants table (v12 schema)
      await txn.execute('''
        CREATE TABLE IF NOT EXISTS class_participants (
          id TEXT PRIMARY KEY,
          local_id TEXT,
          class_id TEXT NOT NULL,
          user_id TEXT NOT NULL,
          username TEXT NOT NULL,
          full_name TEXT NOT NULL,
          role TEXT NOT NULL,
          account_status TEXT NOT NULL,
          joined_at TEXT NOT NULL,
          updated_at TEXT NOT NULL,
          removed_at TEXT,
          cached_at TEXT NOT NULL,
          sync_status TEXT NOT NULL DEFAULT 'synced',
          is_offline_mutation INTEGER NOT NULL DEFAULT 0,
          FOREIGN KEY(class_id) REFERENCES classes(id) ON DELETE CASCADE
        )
      ''');

      // Assessments table
      await txn.execute('''
        CREATE TABLE IF NOT EXISTS assessments (
          id TEXT PRIMARY KEY,
          local_id TEXT,
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
          deleted_at TEXT,
          cached_at TEXT NOT NULL,
          synced_at TEXT,
          is_offline_mutation INTEGER NOT NULL DEFAULT 0,
          sync_status TEXT NOT NULL DEFAULT 'synced',
          FOREIGN KEY(class_id) REFERENCES classes(id) ON DELETE CASCADE
        )
      ''');

      // Questions table
      await txn.execute('''
        CREATE TABLE IF NOT EXISTS questions (
          id TEXT PRIMARY KEY,
          local_id TEXT,
          assessment_id TEXT NOT NULL,
          question_type TEXT NOT NULL,
          question_text TEXT NOT NULL,
          points INTEGER NOT NULL,
          order_index INTEGER NOT NULL,
          is_multi_select INTEGER NOT NULL DEFAULT 0,
          choices_json TEXT,
          correct_answers_json TEXT,
          enumeration_items_json TEXT,
          updated_at TEXT NOT NULL,
          deleted_at TEXT,
          cached_at TEXT NOT NULL,
          sync_status TEXT NOT NULL DEFAULT 'synced',
          is_offline_mutation INTEGER NOT NULL DEFAULT 0,
          FOREIGN KEY(assessment_id) REFERENCES assessments(id) ON DELETE CASCADE
        )
      ''');

      // Assessment submissions table
      await txn.execute('''
        CREATE TABLE IF NOT EXISTS assessment_submissions (
          id TEXT PRIMARY KEY,
          local_id TEXT,
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
          updated_at TEXT NOT NULL,
          deleted_at TEXT,
          cached_at TEXT NOT NULL,
          synced_at TEXT,
          is_offline_mutation INTEGER NOT NULL DEFAULT 0,
          sync_status TEXT NOT NULL DEFAULT 'synced',
          FOREIGN KEY(assessment_id) REFERENCES assessments(id) ON DELETE CASCADE
        )
      ''');

      // Assignments table
      await txn.execute('''
        CREATE TABLE IF NOT EXISTS assignments (
          id TEXT PRIMARY KEY,
          local_id TEXT,
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
          deleted_at TEXT,
          cached_at TEXT NOT NULL,
          synced_at TEXT,
          is_offline_mutation INTEGER NOT NULL DEFAULT 0,
          sync_status TEXT NOT NULL DEFAULT 'synced',
          FOREIGN KEY(class_id) REFERENCES classes(id) ON DELETE CASCADE
        )
      ''');

      // Assignment submissions table
      await txn.execute('''
        CREATE TABLE IF NOT EXISTS assignment_submissions (
          id TEXT PRIMARY KEY,
          local_id TEXT,
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
          deleted_at TEXT,
          cached_at TEXT NOT NULL,
          synced_at TEXT,
          is_offline_mutation INTEGER NOT NULL DEFAULT 0,
          sync_status TEXT NOT NULL DEFAULT 'synced',
          FOREIGN KEY(assignment_id) REFERENCES assignments(id) ON DELETE CASCADE
        )
      ''');

      // Submission files table
      await txn.execute('''
        CREATE TABLE IF NOT EXISTS submission_files (
          id TEXT PRIMARY KEY,
          local_id TEXT,
          submission_id TEXT NOT NULL,
          file_name TEXT NOT NULL,
          file_type TEXT NOT NULL,
          file_size INTEGER NOT NULL,
          uploaded_at TEXT NOT NULL,
          local_path TEXT,
          is_local_only INTEGER NOT NULL DEFAULT 0,
          deleted_at TEXT,
          cached_at TEXT NOT NULL,
          FOREIGN KEY(submission_id) REFERENCES assignment_submissions(id) ON DELETE CASCADE
        )
      ''');

      // Learning materials table
      await txn.execute('''
        CREATE TABLE IF NOT EXISTS learning_materials (
          id TEXT PRIMARY KEY,
          local_id TEXT,
          class_id TEXT NOT NULL,
          title TEXT NOT NULL,
          description TEXT,
          content_text TEXT,
          order_index INTEGER NOT NULL DEFAULT 0,
          file_count INTEGER NOT NULL DEFAULT 0,
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL,
          deleted_at TEXT,
          cached_at TEXT NOT NULL,
          synced_at TEXT,
          is_offline_mutation INTEGER NOT NULL DEFAULT 0,
          sync_status TEXT NOT NULL DEFAULT 'synced',
          FOREIGN KEY(class_id) REFERENCES classes(id) ON DELETE CASCADE
        )
      ''');

      // Material files table
      await txn.execute('''
        CREATE TABLE IF NOT EXISTS material_files (
          id TEXT PRIMARY KEY,
          local_id TEXT,
          material_id TEXT NOT NULL,
          file_name TEXT NOT NULL,
          file_type TEXT NOT NULL,
          file_size INTEGER NOT NULL,
          uploaded_at TEXT NOT NULL,
          local_path TEXT,
          is_cached INTEGER NOT NULL DEFAULT 0,
          is_compressed INTEGER NOT NULL DEFAULT 0,
          deleted_at TEXT,
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

      // Activity logs table
      await txn.execute('''
        CREATE TABLE IF NOT EXISTS activity_logs (
          id TEXT PRIMARY KEY,
          user_id TEXT NOT NULL,
          action TEXT NOT NULL,
          performed_by TEXT,
          details TEXT,
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL,
          deleted_at TEXT,
          cached_at TEXT NOT NULL,
          sync_status TEXT NOT NULL DEFAULT 'synced',
          FOREIGN KEY(user_id) REFERENCES users(id) ON DELETE CASCADE
        )
      ''');

      // Assessment statistics cache table
      await txn.execute('''
        CREATE TABLE IF NOT EXISTS assessment_statistics_cache (
          assessment_id TEXT PRIMARY KEY,
          statistics_json TEXT NOT NULL,
          cached_at TEXT NOT NULL
        )
      ''');

      // Student results cache table
      await txn.execute('''
        CREATE TABLE IF NOT EXISTS student_results_cache (
          submission_id TEXT PRIMARY KEY,
          results_json TEXT NOT NULL,
          cached_at TEXT NOT NULL
        )
      ''');

      // Create indexes for common queries
      await txn.execute('CREATE INDEX IF NOT EXISTS idx_classes_teacher_id ON classes(teacher_id)');
      await txn.execute('CREATE INDEX IF NOT EXISTS idx_classes_updated_at ON classes(updated_at)');
      await txn.execute('CREATE INDEX IF NOT EXISTS idx_classes_deleted_at ON classes(deleted_at)');
      await txn.execute('CREATE INDEX IF NOT EXISTS idx_class_participants_class_id ON class_participants(class_id)');
      await txn.execute('CREATE INDEX IF NOT EXISTS idx_class_participants_user_id ON class_participants(user_id)');
      await txn.execute('CREATE INDEX IF NOT EXISTS idx_class_participants_removed_at ON class_participants(removed_at)');
      await txn.execute('CREATE INDEX IF NOT EXISTS idx_assessments_class_id ON assessments(class_id)');
      await txn.execute('CREATE INDEX IF NOT EXISTS idx_assessments_updated_at ON assessments(updated_at)');
      await txn.execute('CREATE INDEX IF NOT EXISTS idx_assessments_deleted_at ON assessments(deleted_at)');
      await txn.execute('CREATE INDEX IF NOT EXISTS idx_questions_assessment_id ON questions(assessment_id)');
      await txn.execute('CREATE INDEX IF NOT EXISTS idx_questions_updated_at ON questions(updated_at)');
      await txn.execute('CREATE INDEX IF NOT EXISTS idx_questions_deleted_at ON questions(deleted_at)');
      await txn.execute('CREATE INDEX IF NOT EXISTS idx_assessment_submissions_assessment_id ON assessment_submissions(assessment_id)');
      await txn.execute('CREATE INDEX IF NOT EXISTS idx_assessment_submissions_updated_at ON assessment_submissions(updated_at)');
      await txn.execute('CREATE INDEX IF NOT EXISTS idx_assessment_submissions_deleted_at ON assessment_submissions(deleted_at)');
      await txn.execute('CREATE INDEX IF NOT EXISTS idx_assignments_class_id ON assignments(class_id)');
      await txn.execute('CREATE INDEX IF NOT EXISTS idx_assignments_updated_at ON assignments(updated_at)');
      await txn.execute('CREATE INDEX IF NOT EXISTS idx_assignments_deleted_at ON assignments(deleted_at)');
      await txn.execute('CREATE INDEX IF NOT EXISTS idx_assignment_submissions_assignment_id ON assignment_submissions(assignment_id)');
      await txn.execute('CREATE INDEX IF NOT EXISTS idx_assignment_submissions_updated_at ON assignment_submissions(updated_at)');
      await txn.execute('CREATE INDEX IF NOT EXISTS idx_assignment_submissions_deleted_at ON assignment_submissions(deleted_at)');
      await txn.execute('CREATE INDEX IF NOT EXISTS idx_submission_files_submission_id ON submission_files(submission_id)');
      await txn.execute('CREATE INDEX IF NOT EXISTS idx_learning_materials_class_id ON learning_materials(class_id)');
      await txn.execute('CREATE INDEX IF NOT EXISTS idx_learning_materials_updated_at ON learning_materials(updated_at)');
      await txn.execute('CREATE INDEX IF NOT EXISTS idx_learning_materials_deleted_at ON learning_materials(deleted_at)');
      await txn.execute('CREATE INDEX IF NOT EXISTS idx_material_files_material_id ON material_files(material_id)');
      await txn.execute('CREATE INDEX IF NOT EXISTS idx_sync_queue_status ON sync_queue(status)');
      await txn.execute('CREATE INDEX IF NOT EXISTS idx_sync_queue_created_at ON sync_queue(created_at)');
      await txn.execute('CREATE INDEX IF NOT EXISTS idx_sync_metadata_key ON sync_metadata(key)');
      await txn.execute('CREATE INDEX IF NOT EXISTS idx_activity_logs_user_id ON activity_logs(user_id)');
      await txn.execute('CREATE INDEX IF NOT EXISTS idx_activity_logs_created_at ON activity_logs(created_at)');
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

    if (oldVersion < 3) {
      // Add synced_at and is_offline_mutation columns to entity tables
      final tables = [
        'classes',
        'assessments',
        'assignments',
        'assessment_submissions',
        'assignment_submissions',
        'learning_materials',
      ];

      for (final table in tables) {
        try {
          await db.execute('ALTER TABLE $table ADD COLUMN synced_at TEXT');
        } catch (e) {
          // Column might already exist
        }

        try {
          await db.execute(
              'ALTER TABLE $table ADD COLUMN is_offline_mutation INTEGER NOT NULL DEFAULT 0');
        } catch (e) {
          // Column might already exist
        }
      }
    }

    if (oldVersion < 4) {
      // Add local_id and deleted_at columns to syncable tables for ID reconciliation and tombstone handling
      final syncableTables = [
        'classes',
        'class_enrollments',
        'assessments',
        'questions',
        'assessment_submissions',
        'assignments',
        'assignment_submissions',
        'submission_files',
        'learning_materials',
        'material_files',
      ];

      for (final table in syncableTables) {
        try {
          await db.execute('ALTER TABLE $table ADD COLUMN local_id TEXT');
        } catch (e) {
          // Column might already exist
        }

        try {
          await db.execute('ALTER TABLE $table ADD COLUMN deleted_at TEXT');
        } catch (e) {
          // Column might already exist
        }
      }

      // Create indexes for sync performance
      final indexStatements = [
        'CREATE INDEX IF NOT EXISTS idx_classes_updated_at ON classes(updated_at)',
        'CREATE INDEX IF NOT EXISTS idx_classes_deleted_at ON classes(deleted_at)',
        'CREATE INDEX IF NOT EXISTS idx_assessments_updated_at ON assessments(updated_at)',
        'CREATE INDEX IF NOT EXISTS idx_assessments_deleted_at ON assessments(deleted_at)',
        'CREATE INDEX IF NOT EXISTS idx_questions_updated_at ON questions(updated_at)',
        'CREATE INDEX IF NOT EXISTS idx_questions_deleted_at ON questions(deleted_at)',
        'CREATE INDEX IF NOT EXISTS idx_assessment_submissions_updated_at ON assessment_submissions(updated_at)',
        'CREATE INDEX IF NOT EXISTS idx_assessment_submissions_deleted_at ON assessment_submissions(deleted_at)',
        'CREATE INDEX IF NOT EXISTS idx_assignments_updated_at ON assignments(updated_at)',
        'CREATE INDEX IF NOT EXISTS idx_assignments_deleted_at ON assignments(deleted_at)',
        'CREATE INDEX IF NOT EXISTS idx_assignment_submissions_updated_at ON assignment_submissions(updated_at)',
        'CREATE INDEX IF NOT EXISTS idx_assignment_submissions_deleted_at ON assignment_submissions(deleted_at)',
        'CREATE INDEX IF NOT EXISTS idx_learning_materials_updated_at ON learning_materials(updated_at)',
        'CREATE INDEX IF NOT EXISTS idx_learning_materials_deleted_at ON learning_materials(deleted_at)',
      ];

      for (final indexStatement in indexStatements) {
        try {
          await db.execute(indexStatement);
        } catch (e) {
          // Index might already exist
        }
      }
    }

    if (oldVersion < 5) {
      // Add updated_at and sync_status to questions and class_enrollments tables
      final tablesToMigrate = ['questions', 'class_enrollments'];

      for (final table in tablesToMigrate) {
        try {
          await db.execute('ALTER TABLE $table ADD COLUMN updated_at TEXT');
        } catch (e) {
          // Column might already exist
        }

        try {
          await db.execute('ALTER TABLE $table ADD COLUMN sync_status TEXT DEFAULT "synced"');
        } catch (e) {
          // Column might already exist
        }
      }

      // Create indexes for updated_at on questions and class_enrollments
      try {
        await db.execute('CREATE INDEX IF NOT EXISTS idx_questions_updated_at ON questions(updated_at)');
      } catch (e) {
        // Index might already exist
      }

      try {
        await db.execute('CREATE INDEX IF NOT EXISTS idx_class_enrollments_updated_at ON class_enrollments(updated_at)');
      } catch (e) {
        // Index might already exist
      }
    }

    if (oldVersion < 6) {
      // Create activity_logs table if it doesn't exist
      try {
        await db.execute('''
          CREATE TABLE IF NOT EXISTS activity_logs (
            id TEXT PRIMARY KEY,
            user_id TEXT NOT NULL,
            action TEXT NOT NULL,
            performed_by TEXT,
            details TEXT,
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL,
            deleted_at TEXT,
            cached_at TEXT NOT NULL,
            sync_status TEXT NOT NULL DEFAULT 'synced',
            FOREIGN KEY(user_id) REFERENCES users(id) ON DELETE CASCADE
          )
        ''');
      } catch (e) {
        // Table might already exist
      }

      // Create indexes for activity logs
      try {
        await db.execute('CREATE INDEX IF NOT EXISTS idx_activity_logs_user_id ON activity_logs(user_id)');
      } catch (e) {
        // Index might already exist
      }

      try {
        await db.execute('CREATE INDEX IF NOT EXISTS idx_activity_logs_created_at ON activity_logs(created_at)');
      } catch (e) {
        // Index might already exist
      }
    }

    if (oldVersion < 7) {
      // Add is_compressed column to material_files for gzip compression support
      try {
        await db.execute('''
          ALTER TABLE material_files ADD COLUMN is_compressed INTEGER NOT NULL DEFAULT 0
        ''');
      } catch (e) {
        // Column might already exist
      }
    }

    if (oldVersion < 8) {
      // Create assessment_statistics_cache and student_results_cache tables for offline read caching
      try {
        await db.execute('''
          CREATE TABLE IF NOT EXISTS assessment_statistics_cache (
            assessment_id TEXT PRIMARY KEY,
            statistics_json TEXT NOT NULL,
            cached_at TEXT NOT NULL
          )
        ''');
      } catch (e) {
        // Table might already exist
      }

      try {
        await db.execute('''
          CREATE TABLE IF NOT EXISTS student_results_cache (
            submission_id TEXT PRIMARY KEY,
            results_json TEXT NOT NULL,
            cached_at TEXT NOT NULL
          )
        ''');
      } catch (e) {
        // Table might already exist
      }
    }

    if (oldVersion < 9) {
      // Add completed_at column to sync_queue for audit trail of completed operations
      try {
        await db.execute('ALTER TABLE sync_queue ADD COLUMN completed_at TEXT');
      } catch (e) {
        // Column might already exist
      }
    }

    if (oldVersion < 10) {
      // Standardize users table: add is_offline_mutation column (copy from is_dirty)
      try {
        await db.execute(
          'ALTER TABLE users ADD COLUMN is_offline_mutation INTEGER NOT NULL DEFAULT 0'
        );
      } catch (e) {
        // Column already exists
      }
      try {
        await db.execute('UPDATE users SET is_offline_mutation = is_dirty');
      } catch (e) {
        // Ignore — is_dirty not present on fresh installs
      }

      // Fix crash bug: questions table was missing is_offline_mutation
      try {
        await db.execute(
          'ALTER TABLE questions ADD COLUMN is_offline_mutation INTEGER NOT NULL DEFAULT 0'
        );
      } catch (e) {
        // Column already exists
      }

      // Fix crash bug: class_enrollments table was missing is_offline_mutation
      try {
        await db.execute(
          'ALTER TABLE class_enrollments ADD COLUMN is_offline_mutation INTEGER NOT NULL DEFAULT 0'
        );
      } catch (e) {
        // Column already exists
      }
    }

    if (oldVersion < 11) {
      // Create missing cache tables for existing installs that were fresh-installed at v8+
      try {
        await db.execute('''
          CREATE TABLE IF NOT EXISTS assessment_statistics_cache (
            assessment_id TEXT PRIMARY KEY,
            statistics_json TEXT NOT NULL,
            cached_at TEXT NOT NULL
          )
        ''');
      } catch (_) {}
      try {
        await db.execute('''
          CREATE TABLE IF NOT EXISTS student_results_cache (
            submission_id TEXT PRIMARY KEY,
            results_json TEXT NOT NULL,
            cached_at TEXT NOT NULL
          )
        ''');
      } catch (_) {}
    }

    if (oldVersion < 12) {
      // Migrate from class_enrollments to class_participants
      // 1. Create class_participants table
      try {
        await db.execute('''
          CREATE TABLE IF NOT EXISTS class_participants (
            id TEXT PRIMARY KEY,
            local_id TEXT,
            class_id TEXT NOT NULL,
            user_id TEXT NOT NULL,
            username TEXT NOT NULL,
            full_name TEXT NOT NULL,
            role TEXT NOT NULL,
            account_status TEXT NOT NULL,
            joined_at TEXT NOT NULL,
            updated_at TEXT NOT NULL,
            removed_at TEXT,
            cached_at TEXT NOT NULL,
            sync_status TEXT NOT NULL DEFAULT 'synced',
            is_offline_mutation INTEGER NOT NULL DEFAULT 0,
            FOREIGN KEY(class_id) REFERENCES classes(id) ON DELETE CASCADE
          )
        ''');
      } catch (e) {
        // Table might already exist
      }

      // 2. Create indexes for class_participants
      try {
        await db.execute(
          'CREATE INDEX IF NOT EXISTS idx_class_participants_class_id ON class_participants(class_id)'
        );
      } catch (e) {
        // Index might already exist
      }

      try {
        await db.execute(
          'CREATE INDEX IF NOT EXISTS idx_class_participants_user_id ON class_participants(user_id)'
        );
      } catch (e) {
        // Index might already exist
      }

      try {
        await db.execute(
          'CREATE INDEX IF NOT EXISTS idx_class_participants_removed_at ON class_participants(removed_at)'
        );
      } catch (e) {
        // Index might already exist
      }

      // 3. Migrate students from class_enrollments
      try {
        await db.execute('''
          INSERT INTO class_participants
          (id, local_id, class_id, user_id, username, full_name, role,
           account_status, joined_at, updated_at, removed_at, cached_at,
           sync_status, is_offline_mutation)
          SELECT
            ce.id, ce.local_id, ce.class_id, ce.student_id, ce.username,
            ce.full_name, 'student', ce.account_status,
            ce.enrolled_at, ce.updated_at, ce.deleted_at, ce.cached_at,
            ce.sync_status, ce.is_offline_mutation
          FROM class_enrollments ce
        ''');
      } catch (e) {
        // Might already be migrated
      }

      // 4. Drop old class_enrollments table
      try {
        await db.execute('DROP TABLE IF EXISTS class_enrollments');
      } catch (e) {
        // Table might not exist
      }

      // 5. Add deleted_at column to users table
      try {
        await db.execute('ALTER TABLE users ADD COLUMN deleted_at TEXT');
      } catch (e) {
        // Column might already exist
      }

      // 6. Drop vestigial is_active column from users table
      try {
        await db.execute('ALTER TABLE users DROP COLUMN is_active');
      } catch (e) {
        // Column might already be dropped or not exist
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
