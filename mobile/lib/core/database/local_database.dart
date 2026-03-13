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
      version: 23,
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
          username TEXT UNIQUE NOT NULL,
          full_name TEXT NOT NULL,
          role TEXT NOT NULL,
          account_status TEXT NOT NULL DEFAULT 'pending_activation',
          activated_at TEXT,
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL,
          deleted_at TEXT,
          cached_at TEXT,
          needs_sync INTEGER NOT NULL DEFAULT 0
        )
      ''');

      // Refresh tokens table
      await txn.execute('''
        CREATE TABLE IF NOT EXISTS refresh_tokens (
          id TEXT PRIMARY KEY,
          user_id TEXT NOT NULL,
          token TEXT UNIQUE NOT NULL,
          expires_at TEXT NOT NULL,
          is_revoked INTEGER NOT NULL DEFAULT 0,
          FOREIGN KEY(user_id) REFERENCES users(id) ON DELETE CASCADE
        )
      ''');

      // Login attempts table
      await txn.execute('''
        CREATE TABLE IF NOT EXISTS login_attempts (
          id TEXT PRIMARY KEY,
          user_id TEXT,
          ip_address TEXT NOT NULL,
          attempted_at TEXT NOT NULL,
          success INTEGER NOT NULL DEFAULT 0,
          FOREIGN KEY(user_id) REFERENCES users(id) ON DELETE SET NULL
        )
      ''');

      // Activity logs table
      await txn.execute('''
        CREATE TABLE IF NOT EXISTS activity_logs (
          id TEXT PRIMARY KEY,
          user_id TEXT NOT NULL,
          action TEXT NOT NULL,
          details TEXT,
          created_at TEXT NOT NULL,
          cached_at TEXT,
          needs_sync INTEGER NOT NULL DEFAULT 0,
          FOREIGN KEY(user_id) REFERENCES users(id) ON DELETE CASCADE
        )
      ''');

      // Classes table
      await txn.execute('''
        CREATE TABLE IF NOT EXISTS classes (
          id TEXT PRIMARY KEY,
          title TEXT NOT NULL,
          description TEXT,
          is_archived INTEGER NOT NULL DEFAULT 0,
          teacher_id TEXT NOT NULL DEFAULT '',
          teacher_username TEXT NOT NULL DEFAULT '',
          teacher_full_name TEXT NOT NULL DEFAULT '',
          student_count INTEGER NOT NULL DEFAULT 0,
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL,
          deleted_at TEXT,
          cached_at TEXT,
          needs_sync INTEGER NOT NULL DEFAULT 0
        )
      ''');

      // Class participants table
      await txn.execute('''
        CREATE TABLE IF NOT EXISTS class_participants (
          id TEXT PRIMARY KEY,
          class_id TEXT NOT NULL,
          user_id TEXT NOT NULL,
          joined_at TEXT NOT NULL,
          updated_at TEXT NOT NULL,
          removed_at TEXT,
          cached_at TEXT,
          needs_sync INTEGER NOT NULL DEFAULT 0,
          FOREIGN KEY(class_id) REFERENCES classes(id) ON DELETE CASCADE,
          FOREIGN KEY(user_id) REFERENCES users(id) ON DELETE CASCADE
        )
      ''');

      // Assessments table
      await txn.execute('''
        CREATE TABLE IF NOT EXISTS assessments (
          id TEXT PRIMARY KEY,
          class_id TEXT NOT NULL,
          title TEXT NOT NULL,
          description TEXT,
          time_limit_minutes INTEGER NOT NULL DEFAULT 0,
          open_at TEXT NOT NULL,
          close_at TEXT NOT NULL,
          show_results_immediately INTEGER NOT NULL DEFAULT 0,
          results_released INTEGER NOT NULL DEFAULT 0,
          is_published INTEGER NOT NULL DEFAULT 0,
          order_index INTEGER NOT NULL DEFAULT 0,
          total_points INTEGER NOT NULL DEFAULT 0,
          question_count INTEGER NOT NULL DEFAULT 0,
          submission_count INTEGER NOT NULL DEFAULT 0,
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL,
          deleted_at TEXT,
          cached_at TEXT,
          needs_sync INTEGER NOT NULL DEFAULT 0,
          FOREIGN KEY(class_id) REFERENCES classes(id) ON DELETE CASCADE
        )
      ''');

      // Assessment questions table (renamed from questions)
      await txn.execute('''
        CREATE TABLE IF NOT EXISTS assessment_questions (
          id TEXT PRIMARY KEY,
          assessment_id TEXT NOT NULL,
          question_type TEXT NOT NULL,
          question_text TEXT NOT NULL,
          points INTEGER NOT NULL DEFAULT 0,
          order_index INTEGER NOT NULL DEFAULT 0,
          is_multi_select INTEGER NOT NULL DEFAULT 0,
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL,
          deleted_at TEXT,
          cached_at TEXT,
          needs_sync INTEGER NOT NULL DEFAULT 0,
          FOREIGN KEY(assessment_id) REFERENCES assessments(id) ON DELETE CASCADE
        )
      ''');

      // Answer keys table
      await txn.execute('''
        CREATE TABLE IF NOT EXISTS answer_keys (
          id TEXT PRIMARY KEY,
          question_id TEXT NOT NULL,
          item_type TEXT NOT NULL DEFAULT 'correct_answer',
          cached_at TEXT,
          needs_sync INTEGER NOT NULL DEFAULT 0,
          FOREIGN KEY(question_id) REFERENCES assessment_questions(id) ON DELETE CASCADE
        )
      ''');

      // Answer key acceptable answers table
      await txn.execute('''
        CREATE TABLE IF NOT EXISTS answer_key_acceptable_answers (
          id TEXT PRIMARY KEY,
          answer_key_id TEXT NOT NULL,
          answer_text TEXT NOT NULL,
          cached_at TEXT,
          needs_sync INTEGER NOT NULL DEFAULT 0,
          FOREIGN KEY(answer_key_id) REFERENCES answer_keys(id) ON DELETE CASCADE
        )
      ''');

      // Question choices table
      await txn.execute('''
        CREATE TABLE IF NOT EXISTS question_choices (
          id TEXT PRIMARY KEY,
          question_id TEXT NOT NULL,
          choice_text TEXT NOT NULL,
          is_correct INTEGER NOT NULL DEFAULT 0,
          order_index INTEGER NOT NULL DEFAULT 0,
          cached_at TEXT,
          needs_sync INTEGER NOT NULL DEFAULT 0,
          FOREIGN KEY(question_id) REFERENCES assessment_questions(id) ON DELETE CASCADE
        )
      ''');

      // Assessment submissions table
      await txn.execute('''
        CREATE TABLE IF NOT EXISTS assessment_submissions (
          id TEXT PRIMARY KEY,
          assessment_id TEXT NOT NULL,
          user_id TEXT NOT NULL,
          started_at TEXT NOT NULL,
          submitted_at TEXT,
          total_points INTEGER NOT NULL DEFAULT 0,
          earned_points REAL NOT NULL DEFAULT 0,
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL,
          deleted_at TEXT,
          cached_at TEXT,
          needs_sync INTEGER NOT NULL DEFAULT 0,
          FOREIGN KEY(assessment_id) REFERENCES assessments(id) ON DELETE CASCADE,
          FOREIGN KEY(user_id) REFERENCES users(id) ON DELETE CASCADE,
          UNIQUE(assessment_id, user_id)
        )
      ''');

      // Submission answers table
      await txn.execute('''
        CREATE TABLE IF NOT EXISTS submission_answers (
          id TEXT PRIMARY KEY,
          submission_id TEXT NOT NULL,
          question_id TEXT NOT NULL,
          points REAL NOT NULL DEFAULT 0,
          overridden_by TEXT,
          overridden_at TEXT,
          cached_at TEXT,
          needs_sync INTEGER NOT NULL DEFAULT 0,
          FOREIGN KEY(submission_id) REFERENCES assessment_submissions(id) ON DELETE CASCADE,
          FOREIGN KEY(question_id) REFERENCES assessment_questions(id) ON DELETE CASCADE,
          FOREIGN KEY(overridden_by) REFERENCES users(id) ON DELETE SET NULL
        )
      ''');

      // Submission answer items table
      await txn.execute('''
        CREATE TABLE IF NOT EXISTS submission_answer_items (
          id TEXT PRIMARY KEY,
          submission_answer_id TEXT NOT NULL,
          answer_key_id TEXT,
          choice_id TEXT,
          answer_text TEXT,
          is_correct INTEGER NOT NULL DEFAULT 0,
          cached_at TEXT,
          needs_sync INTEGER NOT NULL DEFAULT 0,
          FOREIGN KEY(submission_answer_id) REFERENCES submission_answers(id) ON DELETE CASCADE,
          FOREIGN KEY(answer_key_id) REFERENCES answer_keys(id) ON DELETE SET NULL,
          FOREIGN KEY(choice_id) REFERENCES question_choices(id) ON DELETE SET NULL
        )
      ''');

      // Assignments table
      await txn.execute('''
        CREATE TABLE IF NOT EXISTS assignments (
          id TEXT PRIMARY KEY,
          class_id TEXT NOT NULL,
          title TEXT NOT NULL,
          instructions TEXT NOT NULL,
          total_points INTEGER NOT NULL DEFAULT 0,
          submission_type TEXT NOT NULL DEFAULT 'text_only',
          allowed_file_types TEXT,
          max_file_size_mb INTEGER,
          due_at TEXT NOT NULL,
          is_published INTEGER NOT NULL DEFAULT 0,
          order_index INTEGER NOT NULL DEFAULT 0,
          submission_count INTEGER NOT NULL DEFAULT 0,
          graded_count INTEGER NOT NULL DEFAULT 0,
          submission_status TEXT,
          submission_id TEXT,
          score INTEGER,
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL,
          deleted_at TEXT,
          cached_at TEXT,
          needs_sync INTEGER NOT NULL DEFAULT 0,
          FOREIGN KEY(class_id) REFERENCES classes(id) ON DELETE CASCADE
        )
      ''');

      // Assignment submissions table
      await txn.execute('''
        CREATE TABLE IF NOT EXISTS assignment_submissions (
          id TEXT PRIMARY KEY,
          assignment_id TEXT NOT NULL,
          student_id TEXT NOT NULL,
          status TEXT NOT NULL DEFAULT 'draft',
          text_content TEXT,
          submitted_at TEXT,
          is_late INTEGER NOT NULL DEFAULT 0,
          points INTEGER,
          feedback TEXT,
          graded_at TEXT,
          graded_by TEXT,
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL,
          deleted_at TEXT,
          cached_at TEXT,
          needs_sync INTEGER NOT NULL DEFAULT 0,
          FOREIGN KEY(assignment_id) REFERENCES assignments(id) ON DELETE CASCADE,
          FOREIGN KEY(student_id) REFERENCES users(id) ON DELETE CASCADE,
          FOREIGN KEY(graded_by) REFERENCES users(id) ON DELETE SET NULL,
          UNIQUE(assignment_id, student_id)
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
          local_path TEXT NOT NULL DEFAULT '',
          uploaded_at TEXT NOT NULL,
          cached_at TEXT,
          needs_sync INTEGER NOT NULL DEFAULT 0,
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
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL,
          deleted_at TEXT,
          cached_at TEXT,
          needs_sync INTEGER NOT NULL DEFAULT 0,
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
          local_path TEXT NOT NULL DEFAULT '',
          uploaded_at TEXT NOT NULL,
          cached_at TEXT,
          needs_sync INTEGER NOT NULL DEFAULT 0,
          FOREIGN KEY(material_id) REFERENCES learning_materials(id) ON DELETE CASCADE
        )
      ''');

      // Sync queue table
      await txn.execute('''
        CREATE TABLE IF NOT EXISTS sync_queue (
          id TEXT PRIMARY KEY,
          entity_type TEXT NOT NULL,
          operation TEXT NOT NULL,
          payload TEXT NOT NULL,
          status TEXT NOT NULL DEFAULT 'pending',
          retry_count INTEGER NOT NULL DEFAULT 0,
          max_retries INTEGER NOT NULL DEFAULT 3,
          created_at TEXT NOT NULL,
          last_attempted_at TEXT,
          completed_at TEXT,
          error_message TEXT
        )
      ''');

      // Sync metadata table
      await txn.execute('''
        CREATE TABLE IF NOT EXISTS sync_metadata (
          key TEXT PRIMARY KEY,
          value TEXT NOT NULL
        )
      ''');

      // Assessment statistics cache (re-add after v18 dropped it)
      await txn.execute('''
        CREATE TABLE IF NOT EXISTS assessment_statistics_cache (
          assessment_id TEXT PRIMARY KEY,
          statistics_json TEXT NOT NULL,
          cached_at TEXT NOT NULL
        )
      ''');

      // Student results cache (re-add after v18 dropped it)
      await txn.execute('''
        CREATE TABLE IF NOT EXISTS student_results_cache (
          submission_id TEXT PRIMARY KEY,
          results_json TEXT NOT NULL,
          cached_at TEXT NOT NULL
        )
      ''');

      // Create v2 indexes
      await txn.execute('CREATE INDEX IF NOT EXISTS idx_class_participants_class_id ON class_participants(class_id)');
      await txn.execute('CREATE INDEX IF NOT EXISTS idx_class_participants_user_id ON class_participants(user_id)');
      await txn.execute('CREATE INDEX IF NOT EXISTS idx_class_participants_removed_at ON class_participants(removed_at)');
      await txn.execute('CREATE INDEX IF NOT EXISTS idx_assessments_class_id ON assessments(class_id)');
      await txn.execute('CREATE INDEX IF NOT EXISTS idx_assessments_updated_at ON assessments(updated_at)');
      await txn.execute('CREATE INDEX IF NOT EXISTS idx_assessments_deleted_at ON assessments(deleted_at)');
      await txn.execute('CREATE INDEX IF NOT EXISTS idx_assessment_questions_assessment_id ON assessment_questions(assessment_id)');
      await txn.execute('CREATE INDEX IF NOT EXISTS idx_assessment_questions_updated_at ON assessment_questions(updated_at)');
      await txn.execute('CREATE INDEX IF NOT EXISTS idx_assessment_questions_deleted_at ON assessment_questions(deleted_at)');
      await txn.execute('CREATE INDEX IF NOT EXISTS idx_assessment_submissions_assessment_id ON assessment_submissions(assessment_id)');
      await txn.execute('CREATE INDEX IF NOT EXISTS idx_assessment_submissions_user_id ON assessment_submissions(user_id)');
      await txn.execute('CREATE INDEX IF NOT EXISTS idx_assessment_submissions_updated_at ON assessment_submissions(updated_at)');
      await txn.execute('CREATE INDEX IF NOT EXISTS idx_assessment_submissions_deleted_at ON assessment_submissions(deleted_at)');
      await txn.execute('CREATE INDEX IF NOT EXISTS idx_assignments_class_id ON assignments(class_id)');
      await txn.execute('CREATE INDEX IF NOT EXISTS idx_assignments_updated_at ON assignments(updated_at)');
      await txn.execute('CREATE INDEX IF NOT EXISTS idx_assignments_deleted_at ON assignments(deleted_at)');
      await txn.execute('CREATE INDEX IF NOT EXISTS idx_assignment_submissions_assignment_id ON assignment_submissions(assignment_id)');
      await txn.execute('CREATE INDEX IF NOT EXISTS idx_assignment_submissions_student_id ON assignment_submissions(student_id)');
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

    if (oldVersion < 13) {
      // Add user_save_path to material_files to track where user saved downloaded files
      try {
        await db.execute(
          'ALTER TABLE material_files ADD COLUMN user_save_path TEXT'
        );
      } catch (e) {
        // Column might already exist
      }
    }

    if (oldVersion < 14) {
      // Add created_at column to assessment_submissions to align with server entity
      // and fix full/delta sync crash (column was missing but sync code inserted it)
      try {
        await db.execute(
          'ALTER TABLE assessment_submissions ADD COLUMN created_at TEXT'
        );
      } catch (e) {
        // Column might already exist on fresh installs at v14+
      }
    }

    if (oldVersion < 15) {
      // Add order_index columns to assignments and assessments for reordering support
      try {
        await db.execute(
          'ALTER TABLE assignments ADD COLUMN order_index INTEGER NOT NULL DEFAULT 0'
        );
      } catch (e) {
        // Column might already exist
      }
      try {
        await db.execute(
          'ALTER TABLE assessments ADD COLUMN order_index INTEGER NOT NULL DEFAULT 0'
        );
      } catch (e) {
        // Column might already exist
      }
    }

    if (oldVersion < 16) {
      // Fix: Create sync_metadata table if it doesn't exist (was missing from upgrade path for v15 and earlier)
      try {
        await db.execute('''
          CREATE TABLE IF NOT EXISTS sync_metadata (
            key TEXT PRIMARY KEY,
            value TEXT NOT NULL
          )
        ''');
      } catch (e) {
        // Table might already exist
      }

      // Create index for sync_metadata if it doesn't exist
      try {
        await db.execute('CREATE INDEX IF NOT EXISTS idx_sync_metadata_key ON sync_metadata(key)');
      } catch (e) {
        // Index might already exist
      }

      // Fix: Add updated_at column to users table if it doesn't exist (was missing from v1-v14 upgrade path)
      try {
        await db.execute('ALTER TABLE users ADD COLUMN updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP');
      } catch (e) {
        // Column might already exist
      }
    }

    if (oldVersion < 17) {
      // Fix: Add updated_at column to assessment_submissions table
      // Was missing from the migration path for v1-v16, causing sync crashes
      try {
        await db.execute(
          'ALTER TABLE assessment_submissions ADD COLUMN updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP'
        );
      } catch (e) {
        // Column might already exist
      }
    }

    if (oldVersion < 18) {
      // Nuclear reset to ERD_MOBILE_v2 schema
      // Drop all tables in reverse FK order, then recreate with v2 schema
      final dropOrder = [
        'student_results_cache',
        'assessment_statistics_cache',
        'submission_answer_items',
        'submission_answers',
        'question_choices',
        'answer_key_acceptable_answers',
        'answer_keys',
        'assessment_submissions',
        'assessment_questions', // renamed from 'questions'
        'assessments',
        'submission_files',
        'assignment_submissions',
        'assignments',
        'material_files',
        'learning_materials',
        'class_participants',
        'activity_logs',
        'login_attempts',
        'refresh_tokens',
        'classes',
        'users',
        'sync_queue',
        'sync_metadata',
        'validation_metadata',
      ];

      for (final table in dropOrder) {
        try {
          await db.execute('DROP TABLE IF EXISTS $table');
        } catch (e) {
          // Table might not exist
        }
      }

      // Recreate all tables with v2 schema
      await _createTables(db, 18);
    }

    if (oldVersion < 19) {
      // Restore denormalized columns removed in v18 nuclear reset that models still reference

      // assessments: restore total_points, question_count, submission_count
      for (final col in [
        'ALTER TABLE assessments ADD COLUMN total_points INTEGER NOT NULL DEFAULT 0',
        'ALTER TABLE assessments ADD COLUMN question_count INTEGER NOT NULL DEFAULT 0',
        'ALTER TABLE assessments ADD COLUMN submission_count INTEGER NOT NULL DEFAULT 0',
      ]) {
        try {
          await db.execute(col);
        } catch (_) {}
      }

      // classes: restore teacher info + student_count
      for (final col in [
        "ALTER TABLE classes ADD COLUMN teacher_id TEXT NOT NULL DEFAULT ''",
        "ALTER TABLE classes ADD COLUMN teacher_username TEXT NOT NULL DEFAULT ''",
        "ALTER TABLE classes ADD COLUMN teacher_full_name TEXT NOT NULL DEFAULT ''",
        'ALTER TABLE classes ADD COLUMN student_count INTEGER NOT NULL DEFAULT 0',
      ]) {
        try {
          await db.execute(col);
        } catch (_) {}
      }

      // assessment_submissions: add earned_points to store actual student score separately
      // from total_points (which is the assessment max)
      try {
        await db.execute(
          'ALTER TABLE assessment_submissions ADD COLUMN earned_points REAL NOT NULL DEFAULT 0'
        );
      } catch (_) {}
    }

    if (oldVersion < 20) {
      // Add submission_status, submission_id, score columns to assignments table
      // to store per-student submission data (fixes E2 bug: grade always 60 offline)
      final assignmentColumns = [
        'ALTER TABLE assignments ADD COLUMN submission_status TEXT',
        'ALTER TABLE assignments ADD COLUMN submission_id TEXT',
        'ALTER TABLE assignments ADD COLUMN score INTEGER',
      ];

      for (final col in assignmentColumns) {
        try {
          await db.execute(col);
        } catch (_) {}
      }
    }

    if (oldVersion < 21) {
      // Fix local_path NOT NULL constraint by migrating null values to empty strings
      try {
        await db.execute("UPDATE submission_files SET local_path = '' WHERE local_path IS NULL");
      } catch (_) {}
      try {
        await db.execute("UPDATE material_files SET local_path = '' WHERE local_path IS NULL");
      } catch (_) {}

      // Add submission_count and graded_count to assignments table
      for (final col in [
        'ALTER TABLE assignments ADD COLUMN submission_count INTEGER NOT NULL DEFAULT 0',
        'ALTER TABLE assignments ADD COLUMN graded_count INTEGER NOT NULL DEFAULT 0',
      ]) {
        try {
          await db.execute(col);
        } catch (_) {}
      }
    }

    if (oldVersion < 22) {
      // Re-create stats cache tables dropped in v18 nuclear reset
      try {
        await db.execute('''CREATE TABLE IF NOT EXISTS assessment_statistics_cache (
          assessment_id TEXT PRIMARY KEY, statistics_json TEXT NOT NULL, cached_at TEXT NOT NULL
        )''');
      } catch (_) {}
      try {
        await db.execute('''CREATE TABLE IF NOT EXISTS student_results_cache (
          submission_id TEXT PRIMARY KEY, results_json TEXT NOT NULL, cached_at TEXT NOT NULL
        )''');
      } catch (_) {}
      // Add item_type discriminator to answer_keys
      try {
        await db.execute(
          "ALTER TABLE answer_keys ADD COLUMN item_type TEXT NOT NULL DEFAULT 'correct_answer'"
        );
      } catch (_) {}
    }

    if (oldVersion < 23) {
      // Add columns that were missing from _createTables at v22 (fresh install crash fix)
      final assignmentCols = [
        'ALTER TABLE assignments ADD COLUMN submission_status TEXT',
        'ALTER TABLE assignments ADD COLUMN submission_id TEXT',
        'ALTER TABLE assignments ADD COLUMN score INTEGER',
      ];
      for (final col in assignmentCols) {
        try {
          await db.execute(col);
        } catch (_) {}
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
