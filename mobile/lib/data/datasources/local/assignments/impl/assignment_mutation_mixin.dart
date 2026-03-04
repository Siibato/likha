import 'package:likha/core/errors/exceptions.dart';
import 'package:likha/core/sync/sync_queue.dart';
import 'package:uuid/uuid.dart';
import '../assignment_local_datasource_base.dart';

mixin AssignmentMutationMixin on AssignmentLocalDataSourceBase {
  @override
  Future<void> createSubmissionLocally({
    required String assignmentId,
    required String studentId,
    required String studentName,
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
            'student_name': studentName,
            'status': 'draft',
            'text_content': '',
            'created_at': now.toIso8601String(),
            'updated_at': now.toIso8601String(),
            'cached_at': now.toIso8601String(),
            'sync_status': 'pending',
            'is_offline_mutation': 1,
          },
        );
        await syncQueue.enqueue(SyncQueueEntry(
          id: const Uuid().v4(),
          entityType: SyncEntityType.assignmentSubmission,
          operation: SyncOperation.create,
          payload: {'local_id': submissionId, 'assignment_id': assignmentId, 'student_id': studentId},
          status: SyncStatus.pending,
          retryCount: 0,
          maxRetries: 5,
          createdAt: now,
        ), txn: txn);
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
      final db = await localDatabase.database;
      final now = DateTime.now();
      await db.transaction((txn) async {
        await txn.update(
          'assignment_submissions',
          {
            'text_content': textContent,
            'updated_at': now.toIso8601String(),
            'is_offline_mutation': 1,
            'sync_status': 'pending',
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
          maxRetries: 5,
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
      await db.transaction((txn) async {
        await txn.update(
          'assignment_submissions',
          {
            'status': 'submitted',
            'submitted_at': now.toIso8601String(),
            'is_offline_mutation': 1,
            'sync_status': 'pending',
            'cached_at': now.toIso8601String(),
          },
          where: 'id = ?',
          whereArgs: [submissionId],
        );
        await syncQueue.enqueue(SyncQueueEntry(
          id: const Uuid().v4(),
          entityType: SyncEntityType.assignmentSubmission,
          operation: SyncOperation.submit,
          payload: {'submission_id': submissionId, 'assignment_id': assignmentId},
          status: SyncStatus.pending,
          retryCount: 0,
          maxRetries: 5,
          createdAt: now,
        ), txn: txn);
      });
    } catch (e) {
      throw CacheException('Failed to submit assignment locally: $e');
    }
  }
}