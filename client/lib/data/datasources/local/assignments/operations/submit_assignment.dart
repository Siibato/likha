import 'package:likha/core/database/db_schema.dart';
import 'package:likha/core/errors/exceptions.dart';
import 'package:likha/core/database/local_database.dart';
import 'package:likha/core/sync/sync_queue.dart';
import 'package:uuid/uuid.dart';

Future<void> submitAssignment(
  LocalDatabase localDatabase,
  SyncQueue syncQueue,
  String submissionId,
  String assignmentId, {
  Transaction? txn,
  String? queueEntryId,
}) async {
  try {
    final now = DateTime.now();

    Future<void> execute(Transaction t) async {
      final result = await t.query(
        DbTables.assignmentSubmissions,
        columns: [AssignmentSubmissionsCols.textContent],
        where: '${CommonCols.id} = ?',
        whereArgs: [submissionId],
      );
      final textContent = result.isNotEmpty ? result.first[AssignmentSubmissionsCols.textContent] as String? : null;

      await t.update(
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
        id: queueEntryId ?? const Uuid().v4(),
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
      ), txn: t);
    }

    if (txn != null) {
      await execute(txn);
    } else {
      final db = await localDatabase.database;
      await db.transaction((innerTxn) => execute(innerTxn));
    }
  } catch (e) {
    throw CacheException('Failed to submit assignment locally: $e');
  }
}
