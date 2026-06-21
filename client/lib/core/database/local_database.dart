import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:sqflite_common/sqflite.dart' hide openDatabase, databaseFactory;
import 'package:likha/core/database/db_schema.dart';
import 'package:likha/core/database/open_database.dart';
import 'package:likha/core/logging/core_logger.dart';

/// Local SQLite Database for offline-first functionality
///
/// SCHEMA VERSION: 19 (v18 → v19: Add teacher_details table)
/// TOTAL TABLES: 37
///
/// This database was consolidated from 12 historical versions into a single
/// clean v1 schema. All migrations are now handled via nuclear reset:
/// - Fresh installs: Create tables via _createTables
/// - Upgrades/Downgrades: Drop all tables and recreate (users must resync)
///
/// TABLE CATEGORIES:
/// - Core: users, refresh_tokens, activity_logs
/// - Classes: classes, class_participants
/// - Assessments: assessments, assessment_questions, answer_keys,
///   answer_key_acceptable_answers, question_choices, assessment_submissions,
///   submission_answers, submission_answer_items
/// - Assignments: assignments, assignment_submissions, submission_files
/// - Materials: learning_materials, material_files
/// - Grading: grade_record, grade_items, grade_scores, term_grades
/// - TOS: table_of_specifications, tos_competencies, melcs
/// - Sync: sync_queue, sync_metadata, student_results_cache, validation_metadata
/// - Setup: school_details
///
/// INDEXES: 40+ indexes for query performance on foreign keys and common filters
class LocalDatabase {
  static final LocalDatabase _instance = LocalDatabase._internal();

  Database? _db;
  String? _dbPassword;

  LocalDatabase._internal();

  factory LocalDatabase() {
    return _instance;
  }

  Future<Database> get database async {
    _db ??= await _initDatabase();
    return _db!;
  }

  Future<void> initialize() async {
    _dbPassword = await _getOrCreateDbPassword();
    await database; // Trigger initialization
  }

  static const _passwordStorageKey = 'db_cipher_key';

  Future<String> _getOrCreateDbPassword() async {
    if (kIsWeb) return '';
    const storage = FlutterSecureStorage(
      aOptions: AndroidOptions(encryptedSharedPreferences: true),
      mOptions: MacOsOptions(useDataProtectionKeyChain: false),
    );
    String? existing = await storage.read(key: _passwordStorageKey);
    if (existing != null && existing.isNotEmpty) return existing;
    final newKey = _generateRandomHex(32);
    await storage.write(key: _passwordStorageKey, value: newKey);
    return newKey;
  }

  static String _generateRandomHex(int bytes) {
    final rng = Random.secure();
    final buf = StringBuffer();
    for (var i = 0; i < bytes; i++) {
      buf.write(rng.nextInt(256).toRadixString(16).padLeft(2, '0'));
    }
    return buf.toString();
  }

  Future<Database> _initDatabase() async {
    final dbPath = await databaseFactory.getDatabasesPath();
    final dbFilePath = '$dbPath/likha.db';

    Future<Database> doOpen() async {
      if (kIsWeb) {
        return databaseFactory.openDatabase(
          dbFilePath,
          options: OpenDatabaseOptions(
            version: 19,
            onCreate: _createTables,
            onUpgrade: _upgradeDatabase,
            onDowngrade: _downgradeDatabase,
            onOpen: (db) async {
              try {
                await db.execute('PRAGMA foreign_keys = ON');
                await db.execute('PRAGMA synchronous = NORMAL');
                await db.execute('PRAGMA cache_size = 10000');
                await db.execute('PRAGMA temp_store = MEMORY');
              } catch (e) {
                CoreLogger.instance.warn('Failed to set database PRAGMA settings: $e');
              }
            },
            singleInstance: true,
          ),
        );
      }
      return openDatabase(
        dbFilePath,
        password: _dbPassword,
        version: 17,
        onCreate: _createTables,
        onUpgrade: _upgradeDatabase,
        onDowngrade: _downgradeDatabase,
        onOpen: (db) async {
          try {
            await db.execute('PRAGMA foreign_keys = ON');
            await db.execute('PRAGMA synchronous = NORMAL');
            await db.execute('PRAGMA cache_size = 10000');
            await db.execute('PRAGMA temp_store = MEMORY');
          } catch (e) {
            CoreLogger.instance.warn('Failed to set database PRAGMA settings: $e');
          }
          // MigrationRunner disabled - all migrations consolidated into _createTables
          // Future migrations will be handled via onUpgrade with version increments
        },
        singleInstance: true,
      );
    }

    try {
      return await doOpen();
    } on DatabaseException catch (e) {
      final msg = e.toString().toLowerCase();
      if (msg.contains('open_failed') ||
          msg.contains('notadatabase') ||
          msg.contains('is not a database')) {
        CoreLogger.instance.warn(
          'Database open failed (likely key mismatch or corruption). '
          'Deleting $dbFilePath and recreating.',
        );
        try {
          await databaseFactory.deleteDatabase(dbFilePath);
        } catch (_) {
          // ignore cleanup errors
        }
        return doOpen();
      }
      rethrow;
    }
  }

  Future<void> _createTables(Database db, int version) async {
    await db.transaction((txn) async {
      // Users table
      await txn.execute('''
        CREATE TABLE IF NOT EXISTS users (
          id TEXT PRIMARY KEY,
          username TEXT UNIQUE NOT NULL,
          first_name TEXT NOT NULL DEFAULT '',
          last_name TEXT NOT NULL DEFAULT '',
          role TEXT NOT NULL,
          account_status TEXT NOT NULL DEFAULT 'pending_activation',
          activated_at TEXT,
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL,
          deleted_at TEXT,
          cached_at TEXT,
          sync_status TEXT NOT NULL DEFAULT 'synced'
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

      // Activity logs table
      await txn.execute('''
        CREATE TABLE IF NOT EXISTS activity_logs (
          id TEXT PRIMARY KEY,
          user_id TEXT NOT NULL,
          action TEXT NOT NULL,
          details TEXT,
          created_at TEXT NOT NULL,
          cached_at TEXT,
          sync_status TEXT NOT NULL DEFAULT 'synced',
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
          school_year TEXT,
          term_type TEXT NOT NULL DEFAULT 'term',
          is_advisory INTEGER NOT NULL DEFAULT 0,
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL,
          deleted_at TEXT,
          cached_at TEXT,
          sync_status TEXT NOT NULL DEFAULT 'synced'
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
          sync_status TEXT NOT NULL DEFAULT 'synced',
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
          term_number INTEGER,
          component TEXT,
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL,
          deleted_at TEXT,
          cached_at TEXT,
          sync_status TEXT NOT NULL DEFAULT 'synced',
          FOREIGN KEY(class_id) REFERENCES classes(id) ON DELETE CASCADE,
          FOREIGN KEY(tos_id) REFERENCES table_of_specifications(id) ON DELETE SET NULL
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
          sync_status TEXT NOT NULL DEFAULT 'synced',
          FOREIGN KEY(assessment_id) REFERENCES assessments(id) ON DELETE CASCADE,
          FOREIGN KEY(tos_competency_id) REFERENCES tos_competencies(id) ON DELETE SET NULL
        )
      ''');

      // Answer keys table
      await txn.execute('''
        CREATE TABLE IF NOT EXISTS answer_keys (
          id TEXT PRIMARY KEY,
          question_id TEXT NOT NULL,
          item_type TEXT NOT NULL DEFAULT 'correct_answer',
          cached_at TEXT,
          sync_status TEXT NOT NULL DEFAULT 'synced',
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
          sync_status TEXT NOT NULL DEFAULT 'synced',
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
          sync_status TEXT NOT NULL DEFAULT 'synced',
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
          sync_status TEXT NOT NULL DEFAULT 'synced',
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
          points REAL,
          overridden_by TEXT,
          overridden_at TEXT,
          cached_at TEXT,
          sync_status TEXT NOT NULL DEFAULT 'synced',
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
          is_correct INTEGER,
          cached_at TEXT,
          sync_status TEXT NOT NULL DEFAULT 'synced',
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
          term_number INTEGER,
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
          sync_status TEXT NOT NULL DEFAULT 'synced',
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
          sync_status TEXT NOT NULL DEFAULT 'synced',
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
          local_path TEXT NOT NULL DEFAULT '',
          uploaded_at TEXT NOT NULL,
          cached_at TEXT,
          deleted_at TEXT,
          sync_status TEXT NOT NULL DEFAULT 'synced',
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
          term_number INTEGER NOT NULL,
          ww_weight REAL NOT NULL DEFAULT 30.0,
          pt_weight REAL NOT NULL DEFAULT 50.0,
          qa_weight REAL NOT NULL DEFAULT 20.0,
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL,
          deleted_at TEXT,
          cached_at TEXT,
          sync_status TEXT NOT NULL DEFAULT 'synced',
          FOREIGN KEY(class_id) REFERENCES classes(id) ON DELETE CASCADE,
          UNIQUE(class_id, term_number)
        )
      ''');

      // Grade items table
      await txn.execute('''
        CREATE TABLE IF NOT EXISTS grade_items (
          id TEXT PRIMARY KEY,
          class_id TEXT NOT NULL,
          title TEXT NOT NULL,
          component TEXT NOT NULL,
          term_number INTEGER NOT NULL,
          total_points REAL NOT NULL,
          source_type TEXT NOT NULL DEFAULT 'manual',
          source_id TEXT,
          order_index INTEGER NOT NULL DEFAULT 0,
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL,
          deleted_at TEXT,
          cached_at TEXT,
          sync_status TEXT NOT NULL DEFAULT 'synced',
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
          sync_status TEXT NOT NULL DEFAULT 'synced',
          FOREIGN KEY(grade_item_id) REFERENCES grade_items(id) ON DELETE CASCADE,
          FOREIGN KEY(student_id) REFERENCES users(id) ON DELETE CASCADE,
          UNIQUE(grade_item_id, student_id)
        )
      ''');

      // Term grades table (renamed from term_grades)
      await txn.execute('''
        CREATE TABLE IF NOT EXISTS term_grades (
          id TEXT PRIMARY KEY,
          class_id TEXT NOT NULL,
          student_id TEXT NOT NULL,
          term_number INTEGER NOT NULL,
          initial_grade REAL,
          transmuted_grade INTEGER,
          is_locked INTEGER NOT NULL DEFAULT 0,
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL,
          deleted_at TEXT,
          cached_at TEXT,
          sync_status TEXT NOT NULL DEFAULT 'synced',
          FOREIGN KEY(class_id) REFERENCES classes(id) ON DELETE CASCADE,
          FOREIGN KEY(student_id) REFERENCES users(id) ON DELETE CASCADE,
          UNIQUE(class_id, student_id, term_number)
        )
      ''');

      // Table of Specifications
      await txn.execute('''
        CREATE TABLE IF NOT EXISTS table_of_specifications (
          id TEXT PRIMARY KEY,
          class_id TEXT NOT NULL,
          term_number INTEGER NOT NULL,
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
          sync_status TEXT NOT NULL DEFAULT 'synced'
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
          sync_status TEXT NOT NULL DEFAULT 'synced',
          FOREIGN KEY (tos_id) REFERENCES table_of_specifications(id) ON DELETE CASCADE
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

      // School details table
      await txn.execute('''
        CREATE TABLE IF NOT EXISTS school_details (
          id TEXT PRIMARY KEY,
          school_name TEXT NOT NULL DEFAULT '',
          school_region TEXT NOT NULL DEFAULT '',
          school_division TEXT NOT NULL DEFAULT '',
          school_year TEXT NOT NULL DEFAULT '',
          school_code TEXT NOT NULL DEFAULT '',
          school_district TEXT,
          school_head_name TEXT,
          school_head_position TEXT,
          cached_at TEXT,
          sync_status TEXT NOT NULL DEFAULT 'synced'
        )
      ''');

      // Learner details table
      await txn.execute('''
        CREATE TABLE IF NOT EXISTS learner_details (
          id TEXT PRIMARY KEY,
          user_id TEXT NOT NULL UNIQUE,
          lrn TEXT,
          age INTEGER,
          sex TEXT,
          track_strand TEXT,
          curriculum TEXT,
          birthdate TEXT,
          birthplace TEXT,
          home_address TEXT,
          father_name TEXT,
          father_contact TEXT,
          mother_name TEXT,
          mother_contact TEXT,
          guardian_name TEXT,
          guardian_contact TEXT,
          date_admitted TEXT,
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL,
          deleted_at TEXT,
          cached_at TEXT,
          sync_status TEXT NOT NULL DEFAULT 'synced',
          FOREIGN KEY(user_id) REFERENCES users(id) ON DELETE CASCADE
        )
      ''');

      // Teacher details table
      await txn.execute('''
        CREATE TABLE IF NOT EXISTS teacher_details (
          id TEXT PRIMARY KEY,
          user_id TEXT NOT NULL UNIQUE,
          license_id TEXT,
          rank TEXT,
          position TEXT,
          sex TEXT,
          birthdate TEXT,
          home_address TEXT,
          date_hired TEXT,
          education_level TEXT,
          specialization TEXT,
          contact_number TEXT,
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL,
          deleted_at TEXT,
          cached_at TEXT,
          sync_status TEXT NOT NULL DEFAULT 'synced',
          FOREIGN KEY(user_id) REFERENCES users(id) ON DELETE CASCADE
        )
      ''');

      // Attendance records table
      await txn.execute('''
        CREATE TABLE IF NOT EXISTS attendance_records (
          id TEXT PRIMARY KEY,
          student_id TEXT NOT NULL,
          class_id TEXT NOT NULL,
          school_year TEXT NOT NULL,
          month TEXT NOT NULL,
          school_days INTEGER NOT NULL DEFAULT 0,
          days_present INTEGER NOT NULL DEFAULT 0,
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL,
          deleted_at TEXT,
          cached_at TEXT,
          sync_status TEXT NOT NULL DEFAULT 'synced',
          FOREIGN KEY(student_id) REFERENCES users(id) ON DELETE CASCADE,
          FOREIGN KEY(class_id) REFERENCES classes(id) ON DELETE CASCADE,
          UNIQUE(student_id, class_id, school_year, month)
        )
      ''');

      // Core values records table
      await txn.execute('''
        CREATE TABLE IF NOT EXISTS core_values_records (
          id TEXT PRIMARY KEY,
          student_id TEXT NOT NULL,
          class_id TEXT NOT NULL,
          school_year TEXT NOT NULL,
          term_number INTEGER NOT NULL,
          core_value_id INTEGER NOT NULL,
          marking TEXT NOT NULL,
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL,
          deleted_at TEXT,
          cached_at TEXT,
          sync_status TEXT NOT NULL DEFAULT 'synced',
          FOREIGN KEY(student_id) REFERENCES users(id) ON DELETE CASCADE,
          FOREIGN KEY(class_id) REFERENCES classes(id) ON DELETE CASCADE
        )
      ''');

      // Student school history table
      await txn.execute('''
        CREATE TABLE IF NOT EXISTS student_school_history (
          id TEXT PRIMARY KEY,
          student_id TEXT NOT NULL,
          school_name TEXT NOT NULL,
          school_id TEXT,
          grade_level TEXT NOT NULL,
          school_year TEXT NOT NULL,
          section TEXT,
          date_from TEXT,
          date_to TEXT,
          record_type TEXT NOT NULL DEFAULT 'previous',
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL,
          deleted_at TEXT,
          cached_at TEXT,
          sync_status TEXT NOT NULL DEFAULT 'synced',
          FOREIGN KEY(student_id) REFERENCES users(id) ON DELETE CASCADE
        )
      ''');

      // Previous school subjects table
      await txn.execute('''
        CREATE TABLE IF NOT EXISTS previous_school_subjects (
          id TEXT PRIMARY KEY,
          student_id TEXT NOT NULL,
          school_history_id TEXT NOT NULL,
          subject_name TEXT NOT NULL,
          subject_group TEXT,
          term_type TEXT NOT NULL DEFAULT 'quarterly',
          final_grade INTEGER,
          descriptor TEXT,
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL,
          deleted_at TEXT,
          cached_at TEXT,
          sync_status TEXT NOT NULL DEFAULT 'synced',
          FOREIGN KEY(student_id) REFERENCES users(id) ON DELETE CASCADE,
          FOREIGN KEY(school_history_id) REFERENCES student_school_history(id) ON DELETE CASCADE
        )
      ''');

      // Previous school term grades table
      await txn.execute('''
        CREATE TABLE IF NOT EXISTS previous_school_term_grades (
          id TEXT PRIMARY KEY,
          subject_id TEXT NOT NULL,
          term_number INTEGER NOT NULL,
          grade INTEGER,
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL,
          deleted_at TEXT,
          cached_at TEXT,
          sync_status TEXT NOT NULL DEFAULT 'synced',
          FOREIGN KEY(subject_id) REFERENCES previous_school_subjects(id) ON DELETE CASCADE,
          UNIQUE(subject_id, term_number)
        )
      ''');

      // Previous school attendance table
      await txn.execute('''
        CREATE TABLE IF NOT EXISTS previous_school_attendance (
          id TEXT PRIMARY KEY,
          student_id TEXT NOT NULL,
          school_history_id TEXT NOT NULL,
          school_year TEXT NOT NULL,
          month TEXT NOT NULL,
          school_days INTEGER NOT NULL DEFAULT 0,
          days_present INTEGER NOT NULL DEFAULT 0,
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL,
          deleted_at TEXT,
          cached_at TEXT,
          sync_status TEXT NOT NULL DEFAULT 'synced',
          FOREIGN KEY(student_id) REFERENCES users(id) ON DELETE CASCADE,
          FOREIGN KEY(school_history_id) REFERENCES student_school_history(id) ON DELETE CASCADE
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
      await txn.execute('CREATE INDEX IF NOT EXISTS idx_grade_record_class_id ON grade_record(class_id)');
      await txn.execute('CREATE INDEX IF NOT EXISTS idx_grade_items_class_id ON grade_items(class_id)');
      await txn.execute('CREATE INDEX IF NOT EXISTS idx_grade_items_updated_at ON grade_items(updated_at)');
      await txn.execute('CREATE INDEX IF NOT EXISTS idx_grade_items_deleted_at ON grade_items(deleted_at)');
      await txn.execute('CREATE INDEX IF NOT EXISTS idx_grade_scores_grade_item_id ON grade_scores(grade_item_id)');
      await txn.execute('CREATE INDEX IF NOT EXISTS idx_grade_scores_student_id ON grade_scores(student_id)');
      await txn.execute('CREATE INDEX IF NOT EXISTS idx_grade_scores_updated_at ON grade_scores(updated_at)');
      await txn.execute('CREATE INDEX IF NOT EXISTS idx_grade_scores_deleted_at ON grade_scores(deleted_at)');
      await txn.execute('CREATE INDEX IF NOT EXISTS idx_term_grades_class_id ON term_grades(class_id)');
      await txn.execute('CREATE INDEX IF NOT EXISTS idx_term_grades_student_id ON term_grades(student_id)');
      await txn.execute('CREATE INDEX IF NOT EXISTS idx_term_grades_updated_at ON term_grades(updated_at)');
      await txn.execute('CREATE INDEX IF NOT EXISTS idx_term_grades_deleted_at ON term_grades(deleted_at)');

      // Student records indexes
      await txn.execute('CREATE INDEX IF NOT EXISTS idx_learner_details_user_id ON learner_details(user_id)');
      await txn.execute('CREATE INDEX IF NOT EXISTS idx_attendance_records_student_id ON attendance_records(student_id)');
      await txn.execute('CREATE INDEX IF NOT EXISTS idx_attendance_records_class_id ON attendance_records(class_id)');
      await txn.execute('CREATE INDEX IF NOT EXISTS idx_attendance_records_school_year ON attendance_records(school_year)');
      await txn.execute('CREATE INDEX IF NOT EXISTS idx_core_values_records_student_id ON core_values_records(student_id)');
      await txn.execute('CREATE INDEX IF NOT EXISTS idx_core_values_records_class_id ON core_values_records(class_id)');
      await txn.execute('CREATE INDEX IF NOT EXISTS idx_student_school_history_student_id ON student_school_history(student_id)');
      await txn.execute('CREATE INDEX IF NOT EXISTS idx_previous_school_subjects_student_id ON previous_school_subjects(student_id)');
      await txn.execute('CREATE INDEX IF NOT EXISTS idx_previous_school_subjects_school_history_id ON previous_school_subjects(school_history_id)');
      await txn.execute('CREATE INDEX IF NOT EXISTS idx_previous_school_term_grades_subject_id ON previous_school_term_grades(subject_id)');
      await txn.execute('CREATE INDEX IF NOT EXISTS idx_previous_school_attendance_student_id ON previous_school_attendance(student_id)');
      await txn.execute('CREATE INDEX IF NOT EXISTS idx_previous_school_attendance_school_history_id ON previous_school_attendance(school_history_id)');
    });
  }

  Future<void> _upgradeDatabase(Database db, int oldVersion, int newVersion) async {
    // Targeted migration: add school_head_name and school_head_position to school_details
    // Web path: 9 → 10; Mobile path: 8 → 9
    if ((oldVersion == 9 && newVersion == 10) || (oldVersion == 8 && newVersion == 9)) {
      await db.transaction((txn) async {
        await txn.execute('ALTER TABLE school_details ADD COLUMN school_head_name TEXT');
        await txn.execute('ALTER TABLE school_details ADD COLUMN school_head_position TEXT');
      });
      return;
    }

    // Targeted migration: make points and is_correct nullable
    // Web path: 7 → 8; Mobile path: 6 → 7
    if ((oldVersion == 7 && newVersion == 8) || (oldVersion == 6 && newVersion == 7)) {
      await db.transaction((txn) async {
        // Migrate submission_answers: points REAL NOT NULL DEFAULT 0 → points REAL
        await txn.execute('''
          CREATE TABLE submission_answers_new (
            id TEXT PRIMARY KEY,
            submission_id TEXT NOT NULL,
            question_id TEXT NOT NULL,
            points REAL,
            overridden_by TEXT,
            overridden_at TEXT,
            cached_at TEXT,
            sync_status TEXT NOT NULL DEFAULT 'synced',
            FOREIGN KEY(submission_id) REFERENCES assessment_submissions(id) ON DELETE CASCADE,
            FOREIGN KEY(question_id) REFERENCES assessment_questions(id) ON DELETE CASCADE,
            FOREIGN KEY(overridden_by) REFERENCES users(id) ON DELETE SET NULL
          )
        ''');
        await txn.execute('''
          INSERT INTO submission_answers_new
          SELECT id, submission_id, question_id, points, overridden_by, overridden_at, cached_at, sync_status
          FROM submission_answers
        ''');
        await txn.execute('DROP TABLE submission_answers');
        await txn.execute('ALTER TABLE submission_answers_new RENAME TO submission_answers');

        // Migrate submission_answer_items: is_correct INTEGER NOT NULL DEFAULT 0 → is_correct INTEGER
        await txn.execute('''
          CREATE TABLE submission_answer_items_new (
            id TEXT PRIMARY KEY,
            submission_answer_id TEXT NOT NULL,
            answer_key_id TEXT,
            choice_id TEXT,
            answer_text TEXT,
            is_correct INTEGER,
            cached_at TEXT,
            sync_status TEXT NOT NULL DEFAULT 'synced',
            FOREIGN KEY(submission_answer_id) REFERENCES submission_answers(id) ON DELETE CASCADE,
            FOREIGN KEY(answer_key_id) REFERENCES answer_keys(id) ON DELETE SET NULL,
            FOREIGN KEY(choice_id) REFERENCES question_choices(id) ON DELETE SET NULL
          )
        ''');
        await txn.execute('''
          INSERT INTO submission_answer_items_new
          SELECT id, submission_answer_id, answer_key_id, choice_id, answer_text, is_correct, cached_at, sync_status
          FROM submission_answer_items
        ''');
        await txn.execute('DROP TABLE submission_answer_items');
        await txn.execute('ALTER TABLE submission_answer_items_new RENAME TO submission_answer_items');
      });
      return;
    }

    // Targeted migration: Split users.full_name into first_name and last_name
    // Web path: 17 → 18; Mobile path: 16 → 17
    if ((oldVersion == 17 && newVersion == 18) || (oldVersion == 16 && newVersion == 17)) {
      // Nuclear reset: all schema changes applied via _createTables
      await _dropAllTables(db);
      await _createTables(db, newVersion);
      return;
    }

    // Targeted migration: Rename period_assessment component to term_assessment
    // Web path: 16 → 17; Mobile path: 15 → 16
    if ((oldVersion == 16 && newVersion == 17) || (oldVersion == 15 && newVersion == 16)) {
      // Nuclear reset: all schema changes applied via _createTables
      await _dropAllTables(db);
      await _createTables(db, newVersion);
      return;
    }

    // Targeted migration: Phase 4 FK constraints — assessments.tos_id, assessment_questions.tos_competency_id
    // Web path: 15 → 16; Mobile path: 14 → 15
    if ((oldVersion == 15 && newVersion == 16) || (oldVersion == 14 && newVersion == 15)) {
      // Nuclear reset: all schema changes applied via _createTables
      await _dropAllTables(db);
      await _createTables(db, newVersion);
      return;
    }

    // Targeted migration: Phase 3 normalization — previous school term grades, drop q1-q4 and days_absent
    // Web path: 14 → 15; Mobile path: 13 → 14
    if ((oldVersion == 14 && newVersion == 15) || (oldVersion == 13 && newVersion == 14)) {
      // Nuclear reset: all schema changes applied via _createTables
      await _dropAllTables(db);
      await _createTables(db, newVersion);
      return;
    }

    // Targeted migration: term renames — term_* → term_*, term_grades → term_grades
    // Web path: 13 → 14; Mobile path: 12 → 13
    if ((oldVersion == 13 && newVersion == 14) || (oldVersion == 12 && newVersion == 13)) {
      // Nuclear reset: all schema changes applied via _createTables
      await _dropAllTables(db);
      await _createTables(db, newVersion);
      return;
    }

    // Targeted migration: add deleted_at column to material_files
    // Web path: 11 → 12; Mobile path: 10 → 11
    if ((oldVersion == 11 && newVersion == 12) || (oldVersion == 10 && newVersion == 11)) {
      await db.transaction((txn) async {
        await txn.execute('ALTER TABLE material_files ADD COLUMN deleted_at TEXT');
      });
      return;
    }

    // Nuclear reset: Drop all tables and recreate with current v1 schema
    // This ensures a clean state for any upgrade from old versions
    // Note: Users will lose local data but can resync from server
    await _dropAllTables(db);
    await _createTables(db, newVersion);
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
      'refresh_tokens',
      'classes',
      'users',
      'sync_queue',
      'sync_metadata',
      'student_results_cache',
      'validation_metadata',
      'term_grades',
      'grade_scores',
      'grade_items',
      'grade_record',
      'tos_competencies',
      'table_of_specifications',
      'melcs',
      'school_details',
      'previous_school_term_grades',
      'previous_school_attendance',
      'previous_school_subjects',
      'student_school_history',
      'core_values_records',
      'attendance_records',
      'learner_details',
    ];

    for (final table in tables) {
      try {
        await db.execute('DROP TABLE IF EXISTS $table');
      } catch (e) {
        // Table might not exist
      }
    }
  }

  /// Returns the persisted `last_sync_at` timestamp, or `null` if no sync has
  /// completed yet. This is the single source of truth for reading the sync
  /// token from `sync_metadata`.
  Future<String?> getLastSyncAt() async {
    final db = await database;
    final rows = await db.query(
      DbTables.syncMetadata,
      columns: [SyncMetadataCols.value],
      where: '${SyncMetadataCols.key} = ?',
      whereArgs: [DbValues.metaLastSyncAt],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return rows.first[SyncMetadataCols.value] as String?;
  }

  /// Persists the `last_sync_at` timestamp. This is the single source of truth
  /// for writing the sync token to `sync_metadata`.
  Future<void> setLastSyncAt(String value) async {
    final db = await database;
    await db.insert(
      DbTables.syncMetadata,
      {
        SyncMetadataCols.key: DbValues.metaLastSyncAt,
        SyncMetadataCols.value: value,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> close() async {
    if (_db != null) {
      await _db!.close();
      _db = null;
    }
  }

  @visibleForTesting
  static Future<void> createSchemaForTesting(Database db) =>
      _instance._createTables(db, 1);

  @visibleForTesting
  static void overrideForTesting(Database db) {
    _instance._db = db;
  }
}
