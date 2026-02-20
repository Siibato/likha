import 'package:likha/core/database/local_database.dart';
import 'package:likha/core/errors/exceptions.dart';
import 'package:likha/core/sync/sync_queue.dart';
import 'package:likha/data/models/assignments/assignment_model.dart';
import 'package:likha/data/models/assignments/assignment_submission_model.dart';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

abstract class AssignmentLocalDataSource {
  Future<List<AssignmentModel>> getCachedAssignments(String classId);
  Future<AssignmentModel> getCachedAssignmentDetail(String assignmentId);
  Future<void> cacheAssignments(List<AssignmentModel> assignments);
  Future<void> cacheAssignmentDetail(AssignmentModel assignment);
  Future<void> createSubmissionLocally({
    required String assignmentId,
    required String studentId,
    required String studentName,
  });
  Future<void> updateSubmissionTextLocally({
    required String submissionId,
    required String textContent,
  });
  Future<void> stageFileForUpload({
    required String submissionId,
    required String fileName,
    required String fileType,
    required int fileSize,
    required String localPath,
  });
  Future<void> submitAssignmentLocally({
    required String submissionId,
    required String assignmentId,
  });
  Future<AssignmentSubmissionModel?> getCachedSubmission(String submissionId);
  Future<void> clearAllCache();
}

class AssignmentLocalDataSourceImpl implements AssignmentLocalDataSource {
  final LocalDatabase _localDatabase;
  final SyncQueue _syncQueue;

  AssignmentLocalDataSourceImpl(this._localDatabase, this._syncQueue);

  @override
  Future<List<AssignmentModel>> getCachedAssignments(String classId) async {
    try {
      final db = await _localDatabase.database;
      final results = await db.query(
        'assignments',
        where: 'class_id = ?',
        whereArgs: [classId],
        orderBy: 'created_at DESC',
      );

      if (results.isEmpty) {
        throw CacheException('No cached assignments for class $classId');
      }

      return results.map(AssignmentModel.fromMap).toList();
    } catch (e) {
      if (e is CacheException) rethrow;
      throw CacheException(e.toString());
    }
  }

  @override
  Future<AssignmentModel> getCachedAssignmentDetail(String assignmentId) async {
    try {
      final db = await _localDatabase.database;
      final results = await db.query(
        'assignments',
        where: 'id = ?',
        whereArgs: [assignmentId],
      );

      if (results.isEmpty) {
        throw CacheException('Assignment $assignmentId not cached');
      }

      return AssignmentModel.fromMap(results.first);
    } catch (e) {
      if (e is CacheException) rethrow;
      throw CacheException(e.toString());
    }
  }

  @override
  Future<void> cacheAssignments(List<AssignmentModel> assignments) async {
    try {
      final db = await _localDatabase.database;
      await db.transaction((txn) async {
        for (final assignment in assignments) {
          final map = assignment.toMap();
          map['cached_at'] = DateTime.now().toIso8601String();
          map['sync_status'] = 'synced';
          map['is_dirty'] = 0;

          await txn.insert(
            'assignments',
            map,
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
      });
    } catch (e) {
      throw CacheException('Failed to cache assignments: $e');
    }
  }

  @override
  Future<void> cacheAssignmentDetail(AssignmentModel assignment) async {
    try {
      final db = await _localDatabase.database;
      final map = assignment.toMap();
      map['cached_at'] = DateTime.now().toIso8601String();
      map['sync_status'] = 'synced';
      map['is_dirty'] = 0;

      await db.insert(
        'assignments',
        map,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      throw CacheException('Failed to cache assignment detail: $e');
    }
  }

  @override
  Future<void> createSubmissionLocally({
    required String assignmentId,
    required String studentId,
    required String studentName,
  }) async {
    try {
      final db = await _localDatabase.database;
      final submissionId = const Uuid().v4();
      final now = DateTime.now();

      await db.transaction((txn) async {
        // Create submission
        await txn.insert(
          'assignment_submissions',
          {
            'id': submissionId,
            'assignment_id': assignmentId,
            'student_id': studentId,
            'student_name': studentName,
            'status': 'draft',
            'text_content': '',
            'created_at': now.toIso8601String(),
            'updated_at': now.toIso8601String(),
            'cached_at': now.toIso8601String(),
            'sync_status': 'pending',
            'is_dirty': 1,
          },
        );

        // Enqueue sync
        await _syncQueue.enqueue(
          SyncQueueEntry(
            id: const Uuid().v4(),
            entityType: SyncEntityType.assignmentSubmission,
            operation: SyncOperation.create,
            payload: {
              'local_id': submissionId,
              'assignment_id': assignmentId,
              'student_id': studentId,
            },
            status: SyncStatus.pending,
            retryCount: 0,
            maxRetries: 5,
            createdAt: now,
          ),
        );
      });
    } catch (e) {
      throw CacheException('Failed to create submission locally: $e');
    }
  }

  @override
  Future<void> updateSubmissionTextLocally({
    required String submissionId,
    required String textContent,
  }) async {
    try {
      final db = await _localDatabase.database;
      final now = DateTime.now();

      await db.transaction((txn) async {
        // Update submission
        await txn.update(
          'assignment_submissions',
          {
            'text_content': textContent,
            'updated_at': now.toIso8601String(),
            'is_dirty': 1,
            'sync_status': 'pending',
            'cached_at': now.toIso8601String(),
          },
          where: 'id = ?',
          whereArgs: [submissionId],
        );

        // Enqueue sync
        await _syncQueue.enqueue(
          SyncQueueEntry(
            id: const Uuid().v4(),
            entityType: SyncEntityType.assignmentSubmission,
            operation: SyncOperation.update,
            payload: {
              'submission_id': submissionId,
              'text_content': textContent,
            },
            status: SyncStatus.pending,
            retryCount: 0,
            maxRetries: 5,
            createdAt: now,
          ),
        );
      });
    } catch (e) {
      throw CacheException('Failed to update submission text: $e');
    }
  }

  @override
  Future<void> stageFileForUpload({
    required String submissionId,
    required String fileName,
    required String fileType,
    required int fileSize,
    required String localPath,
  }) async {
    try {
      final db = await _localDatabase.database;
      final now = DateTime.now();
      final fileId = const Uuid().v4();

      await db.transaction((txn) async {
        // Insert file record
        await txn.insert(
          'submission_files',
          {
            'id': fileId,
            'submission_id': submissionId,
            'file_name': fileName,
            'file_type': fileType,
            'file_size': fileSize,
            'uploaded_at': now.toIso8601String(),
            'local_path': localPath,
            'is_local_only': 1,
            'cached_at': now.toIso8601String(),
          },
        );

        // Enqueue sync for file upload
        await _syncQueue.enqueue(
          SyncQueueEntry(
            id: const Uuid().v4(),
            entityType: SyncEntityType.submissionFile,
            operation: SyncOperation.upload,
            payload: {
              'file_id': fileId,
              'submission_id': submissionId,
              'local_path': localPath,
              'file_name': fileName,
              'file_type': fileType,
              'file_size': fileSize,
            },
            status: SyncStatus.pending,
            retryCount: 0,
            maxRetries: 5,
            createdAt: now,
          ),
        );
      });
    } catch (e) {
      throw CacheException('Failed to stage file for upload: $e');
    }
  }

  @override
  Future<void> submitAssignmentLocally({
    required String submissionId,
    required String assignmentId,
  }) async {
    try {
      final db = await _localDatabase.database;
      final now = DateTime.now();

      await db.transaction((txn) async {
        // Mark as submitted
        await txn.update(
          'assignment_submissions',
          {
            'status': 'submitted',
            'submitted_at': now.toIso8601String(),
            'is_dirty': 1,
            'sync_status': 'pending',
            'cached_at': now.toIso8601String(),
          },
          where: 'id = ?',
          whereArgs: [submissionId],
        );

        // Enqueue sync
        await _syncQueue.enqueue(
          SyncQueueEntry(
            id: const Uuid().v4(),
            entityType: SyncEntityType.assignmentSubmission,
            operation: SyncOperation.submit,
            payload: {
              'submission_id': submissionId,
              'assignment_id': assignmentId,
            },
            status: SyncStatus.pending,
            retryCount: 0,
            maxRetries: 5,
            createdAt: now,
          ),
        );
      });
    } catch (e) {
      throw CacheException('Failed to submit assignment locally: $e');
    }
  }

  @override
  Future<AssignmentSubmissionModel?> getCachedSubmission(String submissionId) async {
    try {
      final db = await _localDatabase.database;
      final results = await db.query(
        'assignment_submissions',
        where: 'id = ?',
        whereArgs: [submissionId],
      );

      if (results.isEmpty) return null;

      final sub = results.first;
      return AssignmentSubmissionModel(
        id: sub['id'] as String,
        assignmentId: sub['assignment_id'] as String,
        studentId: sub['student_id'] as String,
        studentName: sub['student_name'] as String? ?? '',
        status: sub['status'] as String,
        textContent: sub['text_content'] as String?,
        submittedAt: sub['submitted_at'] != null ? DateTime.parse(sub['submitted_at'] as String) : null,
        isLate: (sub['is_late'] as int?) == 1,
        score: sub['score'] as int?,
        feedback: sub['feedback'] as String?,
        gradedAt: sub['graded_at'] != null ? DateTime.parse(sub['graded_at'] as String) : null,
        files: const [],
        createdAt: DateTime.parse(sub['created_at'] as String),
        updatedAt: DateTime.parse(sub['updated_at'] as String),
      );
    } catch (e) {
      throw CacheException('Failed to get cached submission: $e');
    }
  }

  @override
  Future<void> clearAllCache() async {
    try {
      final db = await _localDatabase.database;
      await db.delete('assignments');
      await db.delete('assignment_submissions');
      await db.delete('submission_files');
    } catch (e) {
      throw CacheException('Failed to clear assignment cache: $e');
    }
  }
}
