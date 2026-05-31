import 'package:likha/core/database/db_schema.dart';
import 'package:likha/core/database/local_database.dart';
import 'package:likha/core/errors/exceptions.dart';
import 'package:likha/core/sync/sync_queue.dart';
import 'package:uuid/uuid.dart';

Future<void> gradeEssayLocallyOp(
  LocalDatabase localDatabase,
  SyncQueue syncQueue,
  String answerId,
  double points,
) async {
  try {
    final db = await localDatabase.database;
    final now = DateTime.now();

    await db.transaction((txn) async {
      final answerResults = await txn.query(
        'submission_answers',
        where: 'id = ?',
        whereArgs: [answerId],
      );

      if (answerResults.isNotEmpty) {
        final submissionId = answerResults.first['submission_id'] as String;

        await txn.update(
          'submission_answers',
          {
            SubmissionAnswersCols.points: points,
            SubmissionAnswersCols.overriddenAt: now.toIso8601String(),
          },
          where: 'id = ?',
          whereArgs: [answerId],
        );

        await txn.update(
          'assessment_submissions',
          {
            CommonCols.needsSync: 1,
            CommonCols.updatedAt: now.toIso8601String(),
          },
          where: 'id = ?',
          whereArgs: [submissionId],
        );
      }

      await syncQueue.enqueue(SyncQueueEntry(
        id: const Uuid().v4(),
        entityType: SyncEntityType.assessmentSubmission,
        operation: SyncOperation.gradeEssay,
        payload: {
          'answer_id': answerId,
          'points': points,
        },
        status: SyncStatus.pending,
        retryCount: 0,
        maxRetries: 3,
        createdAt: now,
      ), txn: txn);
    });
  } catch (e) {
    throw CacheException('Failed to grade essay locally: $e');
  }
}
