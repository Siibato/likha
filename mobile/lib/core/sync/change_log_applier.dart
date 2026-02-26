import 'package:sqflite/sqflite.dart';
import 'package:likha/core/database/local_database.dart';
import 'package:likha/core/sync/change_log_model.dart';

class ChangeLogApplier {
  final LocalDatabase _localDatabase;

  ChangeLogApplier(this._localDatabase);

  /// Apply all changes to the local SQLite database
  Future<void> applyAll(List<ChangeLogEntry> entries) async {
    try {
      final db = await _localDatabase.database;

      for (final entry in entries) {
        await _applyEntry(db, entry);
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Apply a single change log entry
  Future<void> _applyEntry(dynamic db, ChangeLogEntry entry) async {
    try {
      switch (entry.entityType) {
        case 'class':
          await _applyClassChange(db, entry);
          break;
        case 'enrollment':
          await _applyEnrollmentChange(db, entry);
          break;
        case 'assessment':
          await _applyAssessmentChange(db, entry);
          break;
        case 'question':
          await _applyQuestionChange(db, entry);
          break;
        case 'assessment_submission':
          await _applyAssessmentSubmissionChange(db, entry);
          break;
        case 'assignment':
          await _applyAssignmentChange(db, entry);
          break;
        case 'assignment_submission':
          await _applyAssignmentSubmissionChange(db, entry);
          break;
        case 'learning_material':
          await _applyLearningMaterialChange(db, entry);
          break;
        case 'material_file':
          await _applyMaterialFileChange(db, entry);
          break;
        case 'user':
          await _applyUserChange(db, entry);
          break;
        default:
          // Unknown entity type - skip
          break;
      }
    } catch (e) {
      // Error applying change - continue with next entry
    }
  }

  Future<void> _applyClassChange(dynamic db, ChangeLogEntry entry) async {
    if (entry.operation == 'delete') {
      await db.delete(
        'classes',
        where: 'id = ?',
        whereArgs: [entry.entityId],
      );
    } else {
      // create or update
      final payload = entry.payload ?? {};
      final row = {
        'id': entry.entityId,
        'title': payload['title'] ?? '',
        'description': payload['description'],
        'teacher_id': payload['teacher_id'] ?? '',
        'teacher_username': payload['teacher_username'] ?? '',
        'teacher_full_name': payload['teacher_full_name'] ?? '',
        'is_archived': (payload['is_archived'] ?? false) ? 1 : 0,
        'student_count': payload['student_count'] ?? 0,
        'created_at': payload['created_at'] ?? '',
        'updated_at': payload['updated_at'] ?? '',
        'cached_at': DateTime.now().toIso8601String(),
        'synced_at': DateTime.now().toIso8601String(),
        'is_offline_mutation': 0,
        'sync_status': 'synced',
      };
      await db.insert(
        'classes',
        row,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
  }

  Future<void> _applyEnrollmentChange(dynamic db, ChangeLogEntry entry) async {
    if (entry.operation == 'delete') {
      await db.delete(
        'class_enrollments',
        where: 'id = ?',
        whereArgs: [entry.entityId],
      );
    } else {
      final payload = entry.payload ?? {};
      final row = {
        'id': entry.entityId,
        'class_id': payload['class_id'] ?? '',
        'student_id': payload['student_id'] ?? '',
        'username': payload['username'] ?? '',
        'full_name': payload['full_name'] ?? '',
        'role': 'student',
        'account_status': payload['account_status'] ?? 'active',
        'is_active': 1,
        'enrolled_at': payload['enrolled_at'] ?? '',
        'cached_at': DateTime.now().toIso8601String(),
      };
      await db.insert(
        'class_enrollments',
        row,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
  }

  Future<void> _applyAssessmentChange(dynamic db, ChangeLogEntry entry) async {
    if (entry.operation == 'delete') {
      await db.delete(
        'assessments',
        where: 'id = ?',
        whereArgs: [entry.entityId],
      );
    } else {
      final payload = entry.payload ?? {};
      final row = {
        'id': entry.entityId,
        'class_id': payload['class_id'] ?? '',
        'title': payload['title'] ?? '',
        'description': payload['description'],
        'time_limit_minutes': payload['time_limit_minutes'] ?? 0,
        'open_at': payload['open_at'] ?? '',
        'close_at': payload['close_at'] ?? '',
        'show_results_immediately': (payload['show_results_immediately'] ?? true) ? 1 : 0,
        'results_released': (payload['results_released'] ?? false) ? 1 : 0,
        'is_published': (payload['is_published'] ?? false) ? 1 : 0,
        'total_points': payload['total_points'] ?? 0,
        'created_at': payload['created_at'] ?? '',
        'updated_at': payload['updated_at'] ?? '',
        'cached_at': DateTime.now().toIso8601String(),
        'synced_at': DateTime.now().toIso8601String(),
        'is_offline_mutation': 0,
        'sync_status': 'synced',
      };
      await db.insert(
        'assessments',
        row,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
  }

  Future<void> _applyQuestionChange(dynamic db, ChangeLogEntry entry) async {
    if (entry.operation == 'delete') {
      await db.delete(
        'questions',
        where: 'id = ?',
        whereArgs: [entry.entityId],
      );
    } else {
      final payload = entry.payload ?? {};
      final row = {
        'id': entry.entityId,
        'assessment_id': payload['assessment_id'] ?? '',
        'question_type': payload['question_type'] ?? 'multiple_choice',
        'question_text': payload['question_text'] ?? '',
        'points': payload['points'] ?? 0,
        'order_index': payload['order_index'] ?? 0,
        'is_multi_select': (payload['is_multi_select'] ?? false) ? 1 : 0,
        'created_at': payload['created_at'] ?? '',
        'updated_at': payload['updated_at'] ?? '',
        'cached_at': DateTime.now().toIso8601String(),
      };
      await db.insert(
        'questions',
        row,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
  }

  Future<void> _applyAssessmentSubmissionChange(
      dynamic db, ChangeLogEntry entry) async {
    if (entry.operation == 'delete') {
      await db.delete(
        'assessment_submissions',
        where: 'id = ?',
        whereArgs: [entry.entityId],
      );
    } else {
      final payload = entry.payload ?? {};
      final row = {
        'id': entry.entityId,
        'assessment_id': payload['assessment_id'] ?? '',
        'student_id': payload['student_id'] ?? '',
        'status': payload['status'] ?? 'not_started',
        'score': payload['score'],
        'started_at': payload['started_at'],
        'submitted_at': payload['submitted_at'],
        'cached_at': DateTime.now().toIso8601String(),
        'synced_at': DateTime.now().toIso8601String(),
        'is_offline_mutation': 0,
        'sync_status': 'synced',
      };
      await db.insert(
        'assessment_submissions',
        row,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
  }

  Future<void> _applyAssignmentChange(dynamic db, ChangeLogEntry entry) async {
    if (entry.operation == 'delete') {
      await db.delete(
        'assignments',
        where: 'id = ?',
        whereArgs: [entry.entityId],
      );
    } else {
      final payload = entry.payload ?? {};
      final row = {
        'id': entry.entityId,
        'class_id': payload['class_id'] ?? '',
        'title': payload['title'] ?? '',
        'description': payload['description'],
        'total_points': payload['total_points'] ?? 0,
        'due_date': payload['due_date'],
        'is_published': (payload['is_published'] ?? false) ? 1 : 0,
        'created_at': payload['created_at'] ?? '',
        'updated_at': payload['updated_at'] ?? '',
        'cached_at': DateTime.now().toIso8601String(),
        'synced_at': DateTime.now().toIso8601String(),
        'is_offline_mutation': 0,
        'sync_status': 'synced',
      };
      await db.insert(
        'assignments',
        row,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
  }

  Future<void> _applyAssignmentSubmissionChange(
      dynamic db, ChangeLogEntry entry) async {
    if (entry.operation == 'delete') {
      await db.delete(
        'assignment_submissions',
        where: 'id = ?',
        whereArgs: [entry.entityId],
      );
    } else {
      final payload = entry.payload ?? {};
      final row = {
        'id': entry.entityId,
        'assignment_id': payload['assignment_id'] ?? '',
        'student_id': payload['student_id'] ?? '',
        'status': payload['status'] ?? 'not_started',
        'submitted_at': payload['submitted_at'],
        'graded_at': payload['graded_at'],
        'score': payload['score'],
        'feedback': payload['feedback'],
        'is_late': (payload['is_late'] ?? false) ? 1 : 0,
        'cached_at': DateTime.now().toIso8601String(),
        'synced_at': DateTime.now().toIso8601String(),
        'is_offline_mutation': 0,
        'sync_status': 'synced',
      };
      await db.insert(
        'assignment_submissions',
        row,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
  }

  Future<void> _applyLearningMaterialChange(
      dynamic db, ChangeLogEntry entry) async {
    if (entry.operation == 'delete') {
      await db.delete(
        'learning_materials',
        where: 'id = ?',
        whereArgs: [entry.entityId],
      );
    } else {
      final payload = entry.payload ?? {};
      final row = {
        'id': entry.entityId,
        'class_id': payload['class_id'] ?? '',
        'title': payload['title'] ?? '',
        'description': payload['description'],
        'content_text': payload['content_text'],
        'order_index': payload['order_index'] ?? 0,
        'file_count': payload['file_count'] ?? 0,
        'created_at': payload['created_at'] ?? '',
        'updated_at': payload['updated_at'] ?? '',
        'cached_at': DateTime.now().toIso8601String(),
        'synced_at': DateTime.now().toIso8601String(),
        'is_offline_mutation': 0,
        'sync_status': 'synced',
      };
      await db.insert(
        'learning_materials',
        row,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
  }

  Future<void> _applyMaterialFileChange(dynamic db, ChangeLogEntry entry) async {
    if (entry.operation == 'delete') {
      await db.delete(
        'material_files',
        where: 'id = ?',
        whereArgs: [entry.entityId],
      );
    } else {
      final payload = entry.payload ?? {};
      final row = {
        'id': entry.entityId,
        'material_id': payload['material_id'] ?? '',
        'file_name': payload['file_name'] ?? '',
        'file_type': payload['file_type'] ?? '',
        'file_size': payload['file_size'] ?? 0,
        'uploaded_at': payload['uploaded_at'] ?? '',
        'local_path': null,
        'is_cached': 0,
        'cached_at': DateTime.now().toIso8601String(),
      };
      await db.insert(
        'material_files',
        row,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
  }

  Future<void> _applyUserChange(dynamic db, ChangeLogEntry entry) async {
    if (entry.operation == 'delete') {
      await db.delete(
        'users',
        where: 'id = ?',
        whereArgs: [entry.entityId],
      );
    } else {
      final payload = entry.payload ?? {};
      final row = {
        'id': entry.entityId,
        'username': payload['username'] ?? '',
        'full_name': payload['full_name'] ?? '',
        'role': payload['role'] ?? 'student',
        'account_status': payload['account_status'] ?? 'active',
        'is_active': (payload['is_active'] ?? true) ? 1 : 0,
        'activated_at': payload['activated_at'],
        'created_at': payload['created_at'] ?? '',
        'cached_at': DateTime.now().toIso8601String(),
        'sync_status': 'synced',
      };
      await db.insert(
        'users',
        row,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
  }
}
