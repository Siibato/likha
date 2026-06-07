import 'package:likha/core/database/db_schema.dart';
import 'package:likha/core/errors/exceptions.dart';
import 'package:likha/core/database/local_database.dart';
import 'package:likha/core/sync/sync_queue.dart';
import 'package:likha/core/security/encryption_service.dart';
import 'package:uuid/uuid.dart';

Future<void> gradeSubmissionLocallyOp(
  LocalDatabase localDatabase,
  SyncQueue syncQueue,
  EncryptionService enc,
  String submissionId,
  int score,
  String? feedback,
) async {
  try {
    final db = await localDatabase.database;
    final now = DateTime.now();
    await db.transaction((txn) async {
      await txn.update(
        DbTables.assignmentSubmissions,
        {
          AssignmentSubmissionsCols.points: score,
          AssignmentSubmissionsCols.feedback: enc.encryptField(feedback),
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
