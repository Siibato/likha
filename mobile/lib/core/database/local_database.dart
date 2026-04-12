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
      version: 11,
      onCreate: _createTables,
      onUpgrade: _upgradeDatabase,
      onDowngrade: _downgradeDatabase,
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
          performed_by TEXT,
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
          grade_level TEXT,
          subject_group TEXT,
          school_year TEXT,
          semester INTEGER,
          grading_period_type TEXT NOT NULL DEFAULT 'quarter',
          is_advisory INTEGER NOT NULL DEFAULT 0,
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
          tos_id TEXT,
          grading_period_number INTEGER,
          component TEXT,
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
          tos_competency_id TEXT,
          cognitive_level TEXT,
          difficulty TEXT,
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
          total_points REAL NOT NULL DEFAULT 0.0,
          earned_points REAL NOT NULL DEFAULT 0.0,
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
          allows_text_submission INTEGER NOT NULL DEFAULT 1,
          allows_file_submission INTEGER NOT NULL DEFAULT 0,
          allowed_file_types TEXT,
          max_file_size_mb INTEGER,
          due_at TEXT NOT NULL,
          is_published INTEGER NOT NULL DEFAULT 0,
          order_index INTEGER NOT NULL DEFAULT 0,
          grading_period_number INTEGER,
          component TEXT,
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

      // Student results cache table
      await txn.execute('''
        CREATE TABLE IF NOT EXISTS student_results_cache (
          submission_id TEXT PRIMARY KEY,
          results_json TEXT NOT NULL,
          cached_at TEXT NOT NULL
        )
      ''');

      // Grade record table
      await txn.execute('''
        CREATE TABLE IF NOT EXISTS grade_record (
          id TEXT PRIMARY KEY,
          class_id TEXT NOT NULL,
          grading_period_number INTEGER NOT NULL,
          ww_weight REAL NOT NULL DEFAULT 30.0,
          pt_weight REAL NOT NULL DEFAULT 50.0,
          qa_weight REAL NOT NULL DEFAULT 20.0,
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL,
          deleted_at TEXT,
          cached_at TEXT,
          needs_sync INTEGER NOT NULL DEFAULT 0,
          FOREIGN KEY(class_id) REFERENCES classes(id) ON DELETE CASCADE,
          UNIQUE(class_id, grading_period_number)
        )
      ''');

      // Grade items table
      await txn.execute('''
        CREATE TABLE IF NOT EXISTS grade_items (
          id TEXT PRIMARY KEY,
          class_id TEXT NOT NULL,
          title TEXT NOT NULL,
          component TEXT NOT NULL,
          grading_period_number INTEGER NOT NULL,
          total_points REAL NOT NULL,
          is_departmental_exam INTEGER NOT NULL DEFAULT 0,
          source_type TEXT NOT NULL DEFAULT 'manual',
          source_id TEXT,
          order_index INTEGER NOT NULL DEFAULT 0,
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL,
          deleted_at TEXT,
          cached_at TEXT,
          needs_sync INTEGER NOT NULL DEFAULT 0,
          FOREIGN KEY(class_id) REFERENCES classes(id) ON DELETE CASCADE
        )
      ''');

      // Grade scores table
      await txn.execute('''
        CREATE TABLE IF NOT EXISTS grade_scores (
          id TEXT PRIMARY KEY,
          grade_item_id TEXT NOT NULL,
          student_id TEXT NOT NULL,
          score REAL,
          is_auto_populated INTEGER NOT NULL DEFAULT 0,
          override_score REAL,
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL,
          deleted_at TEXT,
          cached_at TEXT,
          needs_sync INTEGER NOT NULL DEFAULT 0,
          FOREIGN KEY(grade_item_id) REFERENCES grade_items(id) ON DELETE CASCADE,
          FOREIGN KEY(student_id) REFERENCES users(id) ON DELETE CASCADE,
          UNIQUE(grade_item_id, student_id)
        )
      ''');

      // Period grades table
      await txn.execute('''
        CREATE TABLE IF NOT EXISTS period_grades (
          id TEXT PRIMARY KEY,
          class_id TEXT NOT NULL,
          student_id TEXT NOT NULL,
          grading_period_number INTEGER NOT NULL,
          initial_grade REAL,
          transmuted_grade INTEGER,
          is_locked INTEGER NOT NULL DEFAULT 0,
          computed_at TEXT,
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL,
          deleted_at TEXT,
          cached_at TEXT,
          needs_sync INTEGER NOT NULL DEFAULT 0,
          FOREIGN KEY(class_id) REFERENCES classes(id) ON DELETE CASCADE,
          FOREIGN KEY(student_id) REFERENCES users(id) ON DELETE CASCADE,
          UNIQUE(class_id, student_id, grading_period_number)
        )
      ''');

      // Table of Specifications
      await txn.execute('''
        CREATE TABLE IF NOT EXISTS table_of_specifications (
          id TEXT PRIMARY KEY,
          class_id TEXT NOT NULL,
          grading_period_number INTEGER NOT NULL,
          title TEXT NOT NULL,
          classification_mode TEXT NOT NULL,
          total_items INTEGER NOT NULL,
          time_unit TEXT NOT NULL DEFAULT 'days',
          easy_percentage REAL NOT NULL DEFAULT 50.0,
          medium_percentage REAL NOT NULL DEFAULT 30.0,
          hard_percentage REAL NOT NULL DEFAULT 20.0,
          remembering_percentage REAL NOT NULL DEFAULT 16.67,
          understanding_percentage REAL NOT NULL DEFAULT 16.67,
          applying_percentage REAL NOT NULL DEFAULT 16.67,
          analyzing_percentage REAL NOT NULL DEFAULT 16.67,
          evaluating_percentage REAL NOT NULL DEFAULT 16.67,
          creating_percentage REAL NOT NULL DEFAULT 16.67,
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL,
          deleted_at TEXT,
          cached_at TEXT,
          needs_sync INTEGER NOT NULL DEFAULT 0,
          UNIQUE(class_id, grading_period_number)
        )
      ''');

      // TOS Competencies
      await txn.execute('''
        CREATE TABLE IF NOT EXISTS tos_competencies (
          id TEXT PRIMARY KEY,
          tos_id TEXT NOT NULL,
          competency_code TEXT,
          competency_text TEXT NOT NULL,
          time_units_taught INTEGER NOT NULL,
          order_index INTEGER NOT NULL DEFAULT 0,
          easy_count INTEGER,
          medium_count INTEGER,
          hard_count INTEGER,
          remembering_count INTEGER,
          understanding_count INTEGER,
          applying_count INTEGER,
          analyzing_count INTEGER,
          evaluating_count INTEGER,
          creating_count INTEGER,
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL,
          deleted_at TEXT,
          cached_at TEXT,
          needs_sync INTEGER NOT NULL DEFAULT 0,
          FOREIGN KEY (tos_id) REFERENCES table_of_specifications(id)
        )
      ''');

      // MELCs reference table
      await txn.execute('''
        CREATE TABLE IF NOT EXISTS melcs (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          subject TEXT NOT NULL,
          grade_level TEXT NOT NULL,
          quarter INTEGER,
          competency_code TEXT NOT NULL,
          competency_text TEXT NOT NULL,
          domain TEXT
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

      // Create indexes
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
      await txn.execute('CREATE INDEX IF NOT EXISTS idx_grade_components_config_class_id ON grade_components_config(class_id)');
      await txn.execute('CREATE INDEX IF NOT EXISTS idx_grade_items_class_id ON grade_items(class_id)');
      await txn.execute('CREATE INDEX IF NOT EXISTS idx_grade_items_updated_at ON grade_items(updated_at)');
      await txn.execute('CREATE INDEX IF NOT EXISTS idx_grade_items_deleted_at ON grade_items(deleted_at)');
      await txn.execute('CREATE INDEX IF NOT EXISTS idx_grade_scores_grade_item_id ON grade_scores(grade_item_id)');
      await txn.execute('CREATE INDEX IF NOT EXISTS idx_grade_scores_student_id ON grade_scores(student_id)');
      await txn.execute('CREATE INDEX IF NOT EXISTS idx_grade_scores_updated_at ON grade_scores(updated_at)');
      await txn.execute('CREATE INDEX IF NOT EXISTS idx_grade_scores_deleted_at ON grade_scores(deleted_at)');
      await txn.execute('CREATE INDEX IF NOT EXISTS idx_quarterly_grades_class_id ON quarterly_grades(class_id)');
      await txn.execute('CREATE INDEX IF NOT EXISTS idx_quarterly_grades_student_id ON quarterly_grades(student_id)');
      await txn.execute('CREATE INDEX IF NOT EXISTS idx_quarterly_grades_updated_at ON quarterly_grades(updated_at)');
      await txn.execute('CREATE INDEX IF NOT EXISTS idx_quarterly_grades_deleted_at ON quarterly_grades(deleted_at)');
    });
  }

  Future<void> _upgradeDatabase(Database db, int oldVersion, int newVersion) async {
    // Handle upgrade: v1 → v2 adds student_results_cache table
    if (oldVersion < 2) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS student_results_cache (
          submission_id TEXT PRIMARY KEY,
          results_json TEXT NOT NULL,
          cached_at TEXT NOT NULL
        )
      ''');
    }

    // Handle upgrade: v2 → v3 adds grading system tables
    if (oldVersion < 3) {
      await db.execute('ALTER TABLE classes ADD COLUMN grade_level TEXT');
      await db.execute('ALTER TABLE classes ADD COLUMN subject_group TEXT');
      await db.execute('ALTER TABLE classes ADD COLUMN school_year TEXT');
      await db.execute('ALTER TABLE classes ADD COLUMN semester INTEGER');

      await db.execute('''
        CREATE TABLE IF NOT EXISTS grade_components_config (
          id TEXT PRIMARY KEY,
          class_id TEXT NOT NULL,
          quarter INTEGER NOT NULL,
          ww_weight REAL NOT NULL DEFAULT 30.0,
          pt_weight REAL NOT NULL DEFAULT 50.0,
          qa_weight REAL NOT NULL DEFAULT 20.0,
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL,
          deleted_at TEXT,
          cached_at TEXT,
          needs_sync INTEGER NOT NULL DEFAULT 0,
          FOREIGN KEY(class_id) REFERENCES classes(id) ON DELETE CASCADE,
          UNIQUE(class_id, quarter)
        )
      ''');

      await db.execute('''
        CREATE TABLE IF NOT EXISTS grade_items (
          id TEXT PRIMARY KEY,
          class_id TEXT NOT NULL,
          title TEXT NOT NULL,
          component TEXT NOT NULL,
          quarter INTEGER NOT NULL,
          total_points REAL NOT NULL,
          is_departmental_exam INTEGER NOT NULL DEFAULT 0,
          source_type TEXT NOT NULL DEFAULT 'manual',
          source_id TEXT,
          order_index INTEGER NOT NULL DEFAULT 0,
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL,
          deleted_at TEXT,
          cached_at TEXT,
          needs_sync INTEGER NOT NULL DEFAULT 0,
          FOREIGN KEY(class_id) REFERENCES classes(id) ON DELETE CASCADE
        )
      ''');

      await db.execute('''
        CREATE TABLE IF NOT EXISTS grade_scores (
          id TEXT PRIMARY KEY,
          grade_item_id TEXT NOT NULL,
          student_id TEXT NOT NULL,
          score REAL,
          is_auto_populated INTEGER NOT NULL DEFAULT 0,
          override_score REAL,
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL,
          deleted_at TEXT,
          cached_at TEXT,
          needs_sync INTEGER NOT NULL DEFAULT 0,
          FOREIGN KEY(grade_item_id) REFERENCES grade_items(id) ON DELETE CASCADE,
          FOREIGN KEY(student_id) REFERENCES users(id) ON DELETE CASCADE,
          UNIQUE(grade_item_id, student_id)
        )
      ''');

      await db.execute('''
        CREATE TABLE IF NOT EXISTS quarterly_grades (
          id TEXT PRIMARY KEY,
          class_id TEXT NOT NULL,
          student_id TEXT NOT NULL,
          quarter INTEGER NOT NULL,
          ww_percentage REAL,
          pt_percentage REAL,
          qa_percentage REAL,
          ww_weighted REAL,
          pt_weighted REAL,
          qa_weighted REAL,
          initial_grade REAL,
          transmuted_grade INTEGER,
          is_complete INTEGER NOT NULL DEFAULT 0,
          computed_at TEXT,
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL,
          deleted_at TEXT,
          cached_at TEXT,
          needs_sync INTEGER NOT NULL DEFAULT 0,
          FOREIGN KEY(class_id) REFERENCES classes(id) ON DELETE CASCADE,
          FOREIGN KEY(student_id) REFERENCES users(id) ON DELETE CASCADE,
          UNIQUE(class_id, student_id, quarter)
        )
      ''');

      await db.execute('CREATE INDEX IF NOT EXISTS idx_grade_components_config_class_id ON grade_components_config(class_id)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_grade_items_class_id ON grade_items(class_id)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_grade_items_updated_at ON grade_items(updated_at)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_grade_items_deleted_at ON grade_items(deleted_at)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_grade_scores_grade_item_id ON grade_scores(grade_item_id)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_grade_scores_student_id ON grade_scores(student_id)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_grade_scores_updated_at ON grade_scores(updated_at)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_grade_scores_deleted_at ON grade_scores(deleted_at)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_quarterly_grades_class_id ON quarterly_grades(class_id)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_quarterly_grades_student_id ON quarterly_grades(student_id)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_quarterly_grades_updated_at ON quarterly_grades(updated_at)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_quarterly_grades_deleted_at ON quarterly_grades(deleted_at)');
    }

    // Handle upgrade: v3 → v4 adds TOS, competencies, MELCs, and new columns
    if (oldVersion < 4) {
      await db.execute('ALTER TABLE classes ADD COLUMN is_advisory INTEGER NOT NULL DEFAULT 0');
      await db.execute('ALTER TABLE assessment_questions ADD COLUMN tos_competency_id TEXT');
      await db.execute('ALTER TABLE assessment_questions ADD COLUMN cognitive_level TEXT');

      await db.execute('''
        CREATE TABLE IF NOT EXISTS table_of_specifications (
          id TEXT PRIMARY KEY,
          class_id TEXT NOT NULL,
          quarter INTEGER NOT NULL,
          title TEXT NOT NULL,
          classification_mode TEXT NOT NULL,
          total_items INTEGER NOT NULL,
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL,
          deleted_at TEXT,
          cached_at TEXT,
          needs_sync INTEGER NOT NULL DEFAULT 0,
          UNIQUE(class_id, quarter)
        )
      ''');

      await db.execute('''
        CREATE TABLE IF NOT EXISTS tos_competencies (
          id TEXT PRIMARY KEY,
          tos_id TEXT NOT NULL,
          competency_code TEXT,
          competency_text TEXT NOT NULL,
          days_taught INTEGER NOT NULL,
          order_index INTEGER NOT NULL DEFAULT 0,
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL,
          deleted_at TEXT,
          cached_at TEXT,
          needs_sync INTEGER NOT NULL DEFAULT 0,
          FOREIGN KEY (tos_id) REFERENCES table_of_specifications(id)
        )
      ''');

      await db.execute('''
        CREATE TABLE IF NOT EXISTS melcs (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          subject TEXT NOT NULL,
          grade_level TEXT NOT NULL,
          quarter INTEGER,
          competency_code TEXT NOT NULL,
          competency_text TEXT NOT NULL,
          domain TEXT
        )
      ''');
    }

    // Handle upgrade: v4 → v5 adds assessment_statistics_cache table
    if (oldVersion < 5) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS assessment_statistics_cache (
          assessment_id TEXT PRIMARY KEY,
          statistics_json TEXT NOT NULL,
          cached_at TEXT NOT NULL
        )
      ''');
    }

    // Handle upgrade: v5 → v6 adds TOS time unit, difficulty percentages, competency counts, assessment linked_tos_id
    if (oldVersion < 6) {
      await db.execute("ALTER TABLE table_of_specifications ADD COLUMN time_unit TEXT NOT NULL DEFAULT 'days'");
      await db.execute('ALTER TABLE table_of_specifications ADD COLUMN easy_percentage REAL NOT NULL DEFAULT 50.0');
      await db.execute('ALTER TABLE table_of_specifications ADD COLUMN medium_percentage REAL NOT NULL DEFAULT 30.0');
      await db.execute('ALTER TABLE table_of_specifications ADD COLUMN hard_percentage REAL NOT NULL DEFAULT 20.0');
      await db.execute('ALTER TABLE tos_competencies ADD COLUMN easy_count INTEGER');
      await db.execute('ALTER TABLE tos_competencies ADD COLUMN medium_count INTEGER');
      await db.execute('ALTER TABLE tos_competencies ADD COLUMN hard_count INTEGER');
      await db.execute('ALTER TABLE assessments ADD COLUMN linked_tos_id TEXT');
    }

    if (oldVersion < 7) {
      await db.execute('ALTER TABLE table_of_specifications ADD COLUMN remembering_percentage REAL NOT NULL DEFAULT 16.67');
      await db.execute('ALTER TABLE table_of_specifications ADD COLUMN understanding_percentage REAL NOT NULL DEFAULT 16.67');
      await db.execute('ALTER TABLE table_of_specifications ADD COLUMN applying_percentage REAL NOT NULL DEFAULT 16.67');
      await db.execute('ALTER TABLE table_of_specifications ADD COLUMN analyzing_percentage REAL NOT NULL DEFAULT 16.67');
      await db.execute('ALTER TABLE table_of_specifications ADD COLUMN evaluating_percentage REAL NOT NULL DEFAULT 16.67');
      await db.execute('ALTER TABLE table_of_specifications ADD COLUMN creating_percentage REAL NOT NULL DEFAULT 16.67');
    }

    if (oldVersion < 8) {
      await db.execute('ALTER TABLE assessments ADD COLUMN quarter INTEGER');
      await db.execute('ALTER TABLE assessments ADD COLUMN component TEXT');
      await db.execute('ALTER TABLE assignments ADD COLUMN quarter INTEGER');
      await db.execute('ALTER TABLE assignments ADD COLUMN component TEXT');
    }

    // Handle upgrade: v8 → v9 ensures quarter/component columns exist on assessments
    // and assignments. Uses try/catch because fresh installs at v9 already have
    // these columns from _createTables and ALTER TABLE would fail on duplicates.
    if (oldVersion < 9) {
      try { await db.execute('ALTER TABLE assessments ADD COLUMN quarter INTEGER'); } catch (_) {}
      try { await db.execute('ALTER TABLE assessments ADD COLUMN component TEXT'); } catch (_) {}
      try { await db.execute('ALTER TABLE assignments ADD COLUMN quarter INTEGER'); } catch (_) {}
      try { await db.execute('ALTER TABLE assignments ADD COLUMN component TEXT'); } catch (_) {}
    }

    // Handle upgrade: v9 → v10 fixes assessment_submissions.total_points type from
    // INTEGER to REAL. The server stores fractional earned scores (e.g. 8.5 / 10) and
    // SQLite INTEGER silently truncates them during sync writes.
    // Uses table-swap pattern because SQLite does not support ALTER COLUMN.
    if (oldVersion < 10) {
      await db.execute('PRAGMA foreign_keys = OFF');
      await db.execute('''
        CREATE TABLE assessment_submissions_v10 (
          id TEXT PRIMARY KEY,
          assessment_id TEXT NOT NULL,
          user_id TEXT NOT NULL,
          started_at TEXT NOT NULL,
          submitted_at TEXT,
          total_points REAL NOT NULL DEFAULT 0.0,
          earned_points REAL NOT NULL DEFAULT 0.0,
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
      await db.execute('''
        INSERT INTO assessment_submissions_v10
        SELECT id, assessment_id, user_id, started_at, submitted_at,
               CAST(total_points AS REAL), earned_points,
               created_at, updated_at, deleted_at, cached_at, needs_sync
        FROM assessment_submissions
      ''');
      await db.execute('DROP TABLE assessment_submissions');
      await db.execute(
        'ALTER TABLE assessment_submissions_v10 RENAME TO assessment_submissions',
      );
      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_assessment_submissions_assessment_id ON assessment_submissions(assessment_id)',
      );
      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_assessment_submissions_user_id ON assessment_submissions(user_id)',
      );
      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_assessment_submissions_updated_at ON assessment_submissions(updated_at)',
      );
      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_assessment_submissions_deleted_at ON assessment_submissions(deleted_at)',
      );
      await db.execute('PRAGMA foreign_keys = ON');
    }

    // Handle upgrade: v10 -> v11 Phase 2 ERD alignment
    if (oldVersion < 11) {
      await db.execute('PRAGMA foreign_keys = OFF');

      // Add new columns to classes table
      try { await db.execute('ALTER TABLE classes ADD COLUMN grading_period_type TEXT NOT NULL DEFAULT \'quarter\''); } catch (_) {}

      // Rename tables using table-swap pattern
      // 1. grade_components_config -> grade_record
      await db.execute('''
        CREATE TABLE grade_record_v11 (
          id TEXT PRIMARY KEY,
          class_id TEXT NOT NULL,
          grading_period_number INTEGER NOT NULL,
          ww_weight REAL NOT NULL DEFAULT 30.0,
          pt_weight REAL NOT NULL DEFAULT 50.0,
          qa_weight REAL NOT NULL DEFAULT 20.0,
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL,
          deleted_at TEXT,
          cached_at TEXT,
          needs_sync INTEGER NOT NULL DEFAULT 0,
          FOREIGN KEY(class_id) REFERENCES classes(id) ON DELETE CASCADE,
          UNIQUE(class_id, grading_period_number)
        )
      ''');
      await db.execute('''
        INSERT INTO grade_record_v11
        SELECT id, class_id, quarter, ww_weight, pt_weight, qa_weight,
               created_at, updated_at, deleted_at, cached_at, needs_sync
        FROM grade_components_config
      ''');
      await db.execute('DROP TABLE grade_components_config');
      await db.execute('ALTER TABLE grade_record_v11 RENAME TO grade_record');

      // 2. quarterly_grades -> period_grades (remove percentage columns)
      await db.execute('''
        CREATE TABLE period_grades_v11 (
          id TEXT PRIMARY KEY,
          class_id TEXT NOT NULL,
          student_id TEXT NOT NULL,
          grading_period_number INTEGER NOT NULL,
          initial_grade REAL,
          transmuted_grade INTEGER,
          is_locked INTEGER NOT NULL DEFAULT 0,
          computed_at TEXT,
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL,
          deleted_at TEXT,
          cached_at TEXT,
          needs_sync INTEGER NOT NULL DEFAULT 0,
          FOREIGN KEY(class_id) REFERENCES classes(id) ON DELETE CASCADE,
          FOREIGN KEY(student_id) REFERENCES users(id) ON DELETE CASCADE,
          UNIQUE(class_id, student_id, grading_period_number)
        )
      ''');
      await db.execute('''
        INSERT INTO period_grades_v11
        SELECT id, class_id, student_id, quarter, initial_grade, transmuted_grade,
               is_complete, computed_at, created_at, updated_at, deleted_at,
               cached_at, needs_sync
        FROM quarterly_grades
      ''');
      await db.execute('DROP TABLE quarterly_grades');
      await db.execute('ALTER TABLE period_grades_v11 RENAME TO period_grades');

      // Rename columns in existing tables
      // assessments table
      await db.execute('UPDATE assessments SET tos_id = linked_tos_id WHERE linked_tos_id IS NOT NULL');
      // Note: SQLite doesn't support DROP COLUMN, so we'll recreate the table
      
      await db.execute('''
        CREATE TABLE assessments_v11 (
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
          tos_id TEXT,
          grading_period_number INTEGER,
          component TEXT,
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL,
          deleted_at TEXT,
          cached_at TEXT,
          needs_sync INTEGER NOT NULL DEFAULT 0,
          FOREIGN KEY(class_id) REFERENCES classes(id) ON DELETE CASCADE
        )
      ''');
      await db.execute('''
        INSERT INTO assessments_v11
        SELECT id, class_id, title, description, time_limit_minutes, open_at, close_at,
               show_results_immediately, results_released, is_published, order_index,
               total_points, question_count, submission_count, tos_id, quarter, component,
               created_at, updated_at, deleted_at, cached_at, needs_sync
        FROM assessments
      ''');
      await db.execute('DROP TABLE assessments');
      await db.execute('ALTER TABLE assessments_v11 RENAME TO assessments');

      // assignments table (remove submission_type, add allows_* columns)
      await db.execute('''
        CREATE TABLE assignments_v11 (
          id TEXT PRIMARY KEY,
          class_id TEXT NOT NULL,
          title TEXT NOT NULL,
          instructions TEXT NOT NULL,
          total_points INTEGER NOT NULL DEFAULT 0,
          allows_text_submission INTEGER NOT NULL DEFAULT 1,
          allows_file_submission INTEGER NOT NULL DEFAULT 0,
          allowed_file_types TEXT,
          max_file_size_mb INTEGER,
          due_at TEXT NOT NULL,
          is_published INTEGER NOT NULL DEFAULT 0,
          order_index INTEGER NOT NULL DEFAULT 0,
          grading_period_number INTEGER,
          component TEXT,
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
      await db.execute('''
        INSERT INTO assignments_v11
        SELECT id, class_id, title, instructions, total_points,
               CASE WHEN submission_type = 'text_only' OR submission_type = 'both' THEN 1 ELSE 0 END,
               CASE WHEN submission_type = 'file_only' OR submission_type = 'both' THEN 1 ELSE 0 END,
               allowed_file_types, max_file_size_mb, due_at, is_published, order_index,
               quarter, component, submission_count, graded_count, submission_status,
               submission_id, score, created_at, updated_at, deleted_at, cached_at, needs_sync
        FROM assignments
      ''');
      await db.execute('DROP TABLE assignments');
      await db.execute('ALTER TABLE assignments_v11 RENAME TO assignments');

      // assignment_submissions table (remove is_late)
      await db.execute('''
        CREATE TABLE assignment_submissions_v11 (
          id TEXT PRIMARY KEY,
          assignment_id TEXT NOT NULL,
          student_id TEXT NOT NULL,
          status TEXT NOT NULL DEFAULT 'draft',
          text_content TEXT,
          submitted_at TEXT,
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
      await db.execute('''
        INSERT INTO assignment_submissions_v11
        SELECT id, assignment_id, student_id, status, text_content, submitted_at,
               points, feedback, graded_at, graded_by, created_at, updated_at,
               deleted_at, cached_at, needs_sync
        FROM assignment_submissions
      ''');
      await db.execute('DROP TABLE assignment_submissions');
      await db.execute('ALTER TABLE assignment_submissions_v11 RENAME TO assignment_submissions');

      // assessment_questions table (add difficulty)
      try { await db.execute('ALTER TABLE assessment_questions ADD COLUMN difficulty TEXT'); } catch (_) {}

      // grade_items table
      await db.execute('''
        CREATE TABLE grade_items_v11 (
          id TEXT PRIMARY KEY,
          class_id TEXT NOT NULL,
          title TEXT NOT NULL,
          component TEXT NOT NULL,
          grading_period_number INTEGER NOT NULL,
          total_points REAL NOT NULL,
          is_departmental_exam INTEGER NOT NULL DEFAULT 0,
          source_type TEXT NOT NULL DEFAULT 'manual',
          source_id TEXT,
          order_index INTEGER NOT NULL DEFAULT 0,
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL,
          deleted_at TEXT,
          cached_at TEXT,
          needs_sync INTEGER NOT NULL DEFAULT 0,
          FOREIGN KEY(class_id) REFERENCES classes(id) ON DELETE CASCADE
        )
      ''');
      await db.execute('''
        INSERT INTO grade_items_v11
        SELECT id, class_id, title, component, quarter, total_points, is_departmental_exam,
               source_type, source_id, order_index, created_at, updated_at, deleted_at,
               cached_at, needs_sync
        FROM grade_items
      ''');
      await db.execute('DROP TABLE grade_items');
      await db.execute('ALTER TABLE grade_items_v11 RENAME TO grade_items');

      // table_of_specifications table
      await db.execute('''
        CREATE TABLE table_of_specifications_v11 (
          id TEXT PRIMARY KEY,
          class_id TEXT NOT NULL,
          grading_period_number INTEGER NOT NULL,
          title TEXT NOT NULL,
          classification_mode TEXT NOT NULL,
          total_items INTEGER NOT NULL,
          time_unit TEXT NOT NULL DEFAULT 'days',
          easy_percentage REAL NOT NULL DEFAULT 50.0,
          medium_percentage REAL NOT NULL DEFAULT 30.0,
          hard_percentage REAL NOT NULL DEFAULT 20.0,
          remembering_percentage REAL NOT NULL DEFAULT 16.67,
          understanding_percentage REAL NOT NULL DEFAULT 16.67,
          applying_percentage REAL NOT NULL DEFAULT 16.67,
          analyzing_percentage REAL NOT NULL DEFAULT 16.67,
          evaluating_percentage REAL NOT NULL DEFAULT 16.67,
          creating_percentage REAL NOT NULL DEFAULT 16.67,
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL,
          deleted_at TEXT,
          cached_at TEXT,
          needs_sync INTEGER NOT NULL DEFAULT 0,
          UNIQUE(class_id, grading_period_number)
        )
      ''');
      await db.execute('''
        INSERT INTO table_of_specifications_v11
        SELECT id, class_id, quarter, title, classification_mode, total_items, time_unit,
               easy_percentage, medium_percentage, hard_percentage, remembering_percentage,
               understanding_percentage, applying_percentage, analyzing_percentage,
               evaluating_percentage, creating_percentage, created_at, updated_at,
               deleted_at, cached_at, needs_sync
        FROM table_of_specifications
      ''');
      await db.execute('DROP TABLE table_of_specifications');
      await db.execute('ALTER TABLE table_of_specifications_v11 RENAME TO table_of_specifications');

      // tos_competencies table
      await db.execute('''
        CREATE TABLE tos_competencies_v11 (
          id TEXT PRIMARY KEY,
          tos_id TEXT NOT NULL,
          competency_code TEXT,
          competency_text TEXT NOT NULL,
          time_units_taught INTEGER NOT NULL,
          order_index INTEGER NOT NULL DEFAULT 0,
          easy_count INTEGER,
          medium_count INTEGER,
          hard_count INTEGER,
          remembering_count INTEGER,
          understanding_count INTEGER,
          applying_count INTEGER,
          analyzing_count INTEGER,
          evaluating_count INTEGER,
          creating_count INTEGER,
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL,
          deleted_at TEXT,
          cached_at TEXT,
          needs_sync INTEGER NOT NULL DEFAULT 0,
          FOREIGN KEY (tos_id) REFERENCES table_of_specifications(id)
        )
      ''');
      await db.execute('''
        INSERT INTO tos_competencies_v11
        SELECT id, tos_id, competency_code, competency_text, days_taught, order_index,
               easy_count, medium_count, hard_count, remembering_count, understanding_count,
               applying_count, analyzing_count, evaluating_count, creating_count,
               created_at, updated_at, deleted_at, cached_at, needs_sync
        FROM tos_competencies
      ''');
      await db.execute('DROP TABLE tos_competencies');
      await db.execute('ALTER TABLE tos_competencies_v11 RENAME TO tos_competencies');

      await db.execute('PRAGMA foreign_keys = ON');
    }
  }

  Future<void> _downgradeDatabase(Database db, int oldVersion, int newVersion) async {
    // Handle downgrade from higher versions to v1 by doing a nuclear reset
    // Drop all tables in reverse FK order and recreate with v1 schema
    await _dropAllTables(db);
    await _createTables(db, newVersion);
  }

  Future<void> _dropAllTables(Database db) async {
    // Drop tables in reverse FK order
    final tables = [
      'submission_answer_items',
      'submission_answers',
      'question_choices',
      'answer_key_acceptable_answers',
      'answer_keys',
      'assessment_submissions',
      'assessment_questions',
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
      'student_results_cache',
      'period_grades',
      'grade_scores',
      'grade_items',
      'grade_record',
      'tos_competencies',
      'table_of_specifications',
      'melcs',
      'assessment_statistics_cache',
    ];

    for (final table in tables) {
      try {
        await db.execute('DROP TABLE IF EXISTS $table');
      } catch (e) {
        // Table might not exist
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
