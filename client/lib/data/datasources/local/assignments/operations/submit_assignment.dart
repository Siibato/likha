import 'package:likha/core/database/db_schema.dart';
import 'package:likha/core/errors/exceptions.dart';
import 'package:likha/core/database/local_database.dart';
import 'package:likha/core/sync/sync_queue.dart';
import 'package:uuid/uuid.dart';

Future<void> submitAssignment(
  LocalDatabase localDatabase,
  SyncQueue syncQueue,
  String submissionId,
  String assignmentId,
) async {
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
          CommonCols.syncStatus: 'pending',
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
