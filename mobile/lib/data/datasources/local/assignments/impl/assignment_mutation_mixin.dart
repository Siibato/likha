import 'package:likha/core/errors/exceptions.dart';
import 'package:likha/core/sync/sync_queue.dart';
import 'package:uuid/uuid.dart';
import '../assignment_local_datasource_base.dart';

mixin AssignmentMutationMixin on AssignmentLocalDataSourceBase {
  @override
  Future<String> createSubmissionLocally({
    required String assignmentId,
    required String studentId,
    String studentName = '',
    String? textContent,
  }) async {
    try {
      final db = await localDatabase.database;
      final submissionId = const Uuid().v4();
      final now = DateTime.now();
      await db.transaction((txn) async {
        await txn.insert(
          'assignment_submissions',
          {
            'id': submissionId,
            'assignment_id': assignmentId,
            'student_id': studentId,
            'status': 'draft',
            'text_content': textContent ?? '',
            'created_at': now.toIso8601String(),
            'updated_at': now.toIso8601String(),
            'cached_at': now.toIso8601String(),
            'needs_sync': 1,
          },
        );
        await syncQueue.enqueue(SyncQueueEntry(
          id: const Uuid().v4(),
          entityType: SyncEntityType.assignmentSubmission,
          operation: SyncOperation.create,
          payload: {'id': submissionId, 'assignment_id': assignmentId, 'student_id': studentId},
          status: SyncStatus.pending,
          retryCount: 0,
          maxRetries: 3,
          createdAt: now,
        ), txn: txn);
      });
      return submissionId;
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
      final db = await localDatabase.database;
      final now = DateTime.now();
      await db.transaction((txn) async {
        await txn.update(
          'assignment_submissions',
          {
            'text_content': textContent,
            'updated_at': now.toIso8601String(),
            'needs_sync': 1,
            'cached_at': now.toIso8601String(),
          },
          where: 'id = ?',
          whereArgs: [submissionId],
        );
        await syncQueue.enqueue(SyncQueueEntry(
          id: const Uuid().v4(),
          entityType: SyncEntityType.assignmentSubmission,
          operation: SyncOperation.update,
          payload: {'submission_id': submissionId, 'text_content': textContent},
          status: SyncStatus.pending,
          retryCount: 0,
          maxRetries: 3,
          createdAt: now,
        ), txn: txn);
      });
    } catch (e) {
      throw CacheException('Failed to update submission text: $e');
    }
  }

  @override
  Future<void> submitAssignmentLocally({
    required String submissionId,
    required String assignmentId,
  }) async {
    try {
      final db = await localDatabase.database;
      final now = DateTime.now();

      // Fetch current text_content before closing transaction
      final result = await db.query(
        'assignment_submissions',
        columns: ['text_content'],
        where: 'id = ?',
        whereArgs: [submissionId],
      );
      final textContent = result.isNotEmpty ? result.first['text_content'] as String? : null;

      await db.transaction((txn) async {
        await txn.update(
          'assignment_submissions',
          {
            'status': 'submitted',
            'submitted_at': now.toIso8601String(),
            'updated_at': now.toIso8601String(),
            'needs_sync': 1,
            'cached_at': now.toIso8601String(),
          },
          where: 'id = ?',
          whereArgs: [submissionId],
        );
        await syncQueue.enqueue(SyncQueueEntry(
          id: const Uuid().v4(),
          entityType: SyncEntityType.assignmentSubmission,
          operation: SyncOperation.submit,
          payload: {
            'submission_id': submissionId,
            'assignment_id': assignmentId,
            if (textContent != null && textContent.isNotEmpty) 'text_content': textContent,
          },
          status: SyncStatus.pending,
          retryCount: 0,
          maxRetries: 3,
          createdAt: now,
        ), txn: txn);
      });
    } catch (e) {
      throw CacheException('Failed to submit assignment locally: $e');
    }
  }

  @override
  Future<void> gradeSubmissionLocally({
    required String submissionId,
    required int score,
    String? feedback,
  }) async {
    try {
      final db = await localDatabase.database;
      final now = DateTime.now();
      await db.transaction((txn) async {
        await txn.update(
          'assignment_submissions',
          {
            'points': score,
            'feedback': feedback,
            'graded_at': now.toIso8601String(),
            'status': 'graded',
            'needs_sync': 1,
            'updated_at': now.toIso8601String(),
            'cached_at': now.toIso8601String(),
          },
          where: 'id = ?',
          whereArgs: [submissionId],
        );
        await syncQueue.enqueue(SyncQueueEntry(
          id: const Uuid().v4(),
          entityType: SyncEntityType.assignmentSubmission,
          operation: SyncOperation.grade,
          payload: {
            'id': submissionId,
            'score': score,
            if (feedback != null) 'feedback': feedback,
          },
          status: SyncStatus.pending,
          retryCount: 0,
          maxRetries: 3,
          createdAt: now,
        ), txn: txn);
      });
    } catch (e) {
      throw CacheException('Failed to grade submission locally: $e');
    }
  }

  @override
  Future<void> returnSubmissionLocally({
    required String submissionId,
  }) async {
    try {
      final db = await localDatabase.database;
      final now = DateTime.now();
      await db.transaction((txn) async {
        await txn.update(
          'assignment_submissions',
          {
            'status': 'returned',
            'needs_sync': 1,
            'updated_at': now.toIso8601String(),
            'cached_at': now.toIso8601String(),
          },
          where: 'id = ?',
          whereArgs: [submissionId],
        );
        await syncQueue.enqueue(SyncQueueEntry(
          id: const Uuid().v4(),
          entityType: SyncEntityType.assignmentSubmission,
          operation: SyncOperation.update,
          payload: {'id': submissionId, 'action': 'return'},
          status: SyncStatus.pending,
          retryCount: 0,
          maxRetries: 3,
          createdAt: now,
        ), txn: txn);
      });
    } catch (e) {
      throw CacheException('Failed to return submission locally: $e');
    }
  }

  @override
  Future<void> markAssignmentPublishedLocally({required String assignmentId}) async {
    try {
      final db = await localDatabase.database;
      final now = DateTime.now();
      await db.transaction((txn) async {
        await txn.update(
          'assignments',
          {
            'is_published': 1,
            'updated_at': now.toIso8601String(),
            'cached_at': now.toIso8601String(),
            'needs_sync': 1,
          },
          where: 'id = ?',
          whereArgs: [assignmentId],
        );
        await syncQueue.enqueue(SyncQueueEntry(
          id: const Uuid().v4(),
          entityType: SyncEntityType.assignment,
          operation: SyncOperation.update,
          payload: {'id': assignmentId, 'action': 'publish'},
          status: SyncStatus.pending,
          retryCount: 0,
          maxRetries: 3,
          createdAt: now,
        ), txn: txn);
      });
    } catch (e) {
      throw CacheException('Failed to mark assignment as published locally: $e');
    }
  }

  @override
  Future<void> softDeleteSubmissionFile(String fileId) async {
    try {
      final db = await localDatabase.database;
      await db.delete(
        'submission_files',
        where: 'id = ?',
        whereArgs: [fileId],
      );
    } catch (e) {
      throw CacheException('Failed to delete submission file: $e');
    }
  }
}