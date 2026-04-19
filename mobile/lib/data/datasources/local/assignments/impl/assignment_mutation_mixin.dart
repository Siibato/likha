import 'package:likha/core/database/db_schema.dart';
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
      final now = DateTime.now();

      // Check for existing submission (UNIQUE constraint: one per student per assignment)
      final existing = await db.query(
        DbTables.assignmentSubmissions,
        columns: [CommonCols.id],
        where: '${AssignmentSubmissionsCols.assignmentId} = ? AND ${AssignmentSubmissionsCols.studentId} = ?',
        whereArgs: [assignmentId, studentId],
        limit: 1,
      );

      if (existing.isNotEmpty) {
        // Upsert: update text on the existing row, enqueue an update op
        final existingId = existing.first[CommonCols.id] as String;
        await db.transaction((txn) async {
          await txn.update(
            DbTables.assignmentSubmissions,
            {
              AssignmentSubmissionsCols.textContent: textContent ?? '',
              AssignmentSubmissionsCols.status: DbValues.statusDraft,
              CommonCols.updatedAt: now.toIso8601String(),
              CommonCols.cachedAt: now.toIso8601String(),
              CommonCols.needsSync: 1,
            },
            where: '${CommonCols.id} = ?',
            whereArgs: [existingId],
          );
          await syncQueue.enqueue(SyncQueueEntry(
            id: const Uuid().v4(),
            entityType: SyncEntityType.assignmentSubmission,
            operation: SyncOperation.update,
            payload: {'submission_id': existingId, 'text_content': textContent ?? ''},
            status: SyncStatus.pending,
            retryCount: 0,
            maxRetries: 3,
            createdAt: now,
          ), txn: txn);
        });
        return existingId;
      }

      // Fresh insert
      final submissionId = const Uuid().v4();
      await db.transaction((txn) async {
        await txn.insert(
          DbTables.assignmentSubmissions,
          {
            CommonCols.id: submissionId,
            AssignmentSubmissionsCols.assignmentId: assignmentId,
            AssignmentSubmissionsCols.studentId: studentId,
            AssignmentSubmissionsCols.status: DbValues.statusDraft,
            AssignmentSubmissionsCols.textContent: textContent ?? '',
            CommonCols.createdAt: now.toIso8601String(),
            CommonCols.updatedAt: now.toIso8601String(),
            CommonCols.cachedAt: now.toIso8601String(),
            CommonCols.needsSync: 1,
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
          DbTables.assignmentSubmissions,
          {
            AssignmentSubmissionsCols.textContent: textContent,
            CommonCols.updatedAt: now.toIso8601String(),
            CommonCols.needsSync: 1,
            CommonCols.cachedAt: now.toIso8601String(),
          },
          where: '${CommonCols.id} = ?',
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
        DbTables.assignmentSubmissions,
        columns: [AssignmentSubmissionsCols.textContent],
        where: '${CommonCols.id} = ?',
        whereArgs: [submissionId],
      );
      final textContent = result.isNotEmpty ? result.first[AssignmentSubmissionsCols.textContent] as String? : null;

      await db.transaction((txn) async {
        await txn.update(
          DbTables.assignmentSubmissions,
          {
            AssignmentSubmissionsCols.status: DbValues.statusSubmitted,
            AssignmentSubmissionsCols.submittedAt: now.toIso8601String(),
            CommonCols.updatedAt: now.toIso8601String(),
            CommonCols.needsSync: 1,
            CommonCols.cachedAt: now.toIso8601String(),
          },
          where: '${CommonCols.id} = ?',
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
          DbTables.assignmentSubmissions,
          {
            AssignmentSubmissionsCols.points: score,
            AssignmentSubmissionsCols.feedback: feedback,
            AssignmentSubmissionsCols.gradedAt: now.toIso8601String(),
            AssignmentSubmissionsCols.status: DbValues.statusGraded,
            CommonCols.needsSync: 1,
            CommonCols.updatedAt: now.toIso8601String(),
            CommonCols.cachedAt: now.toIso8601String(),
          },
          where: '${CommonCols.id} = ?',
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
          DbTables.assignmentSubmissions,
          {
            AssignmentSubmissionsCols.status: DbValues.statusReturned,
            CommonCols.needsSync: 1,
            CommonCols.updatedAt: now.toIso8601String(),
            CommonCols.cachedAt: now.toIso8601String(),
          },
          where: '${CommonCols.id} = ?',
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
          DbTables.assignments,
          {
            AssignmentsCols.isPublished: 1,
            CommonCols.updatedAt: now.toIso8601String(),
            CommonCols.cachedAt: now.toIso8601String(),
            CommonCols.needsSync: 1,
          },
          where: '${CommonCols.id} = ?',
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
  Future<void> markAssignmentUnpublishedLocally({required String assignmentId}) async {
    try {
      final db = await localDatabase.database;
      final now = DateTime.now();
      await db.transaction((txn) async {
        await txn.update(
          DbTables.assignments,
          {
            AssignmentsCols.isPublished: 0,
            CommonCols.updatedAt: now.toIso8601String(),
            CommonCols.cachedAt: now.toIso8601String(),
            CommonCols.needsSync: 1,
          },
          where: '${CommonCols.id} = ?',
          whereArgs: [assignmentId],
        );
        await syncQueue.enqueue(SyncQueueEntry(
          id: const Uuid().v4(),
          entityType: SyncEntityType.assignment,
          operation: SyncOperation.unpublish,
          payload: {'id': assignmentId},
          status: SyncStatus.pending,
          retryCount: 0,
          maxRetries: 3,
          createdAt: now,
        ), txn: txn);
      });
    } catch (e) {
      throw CacheException('Failed to mark assignment as unpublished locally: $e');
    }
  }

  @override
  Future<void> softDeleteSubmissionFile(String fileId) async {
    try {
      final db = await localDatabase.database;
      await db.delete(
        DbTables.submissionFiles,
        where: '${CommonCols.id} = ?',
        whereArgs: [fileId],
      );
    } catch (e) {
      throw CacheException('Failed to delete submission file: $e');
    }
  }
}