import 'package:dartz/dartz.dart';
import 'package:uuid/uuid.dart';
import 'package:likha/core/errors/failures.dart';
import 'package:likha/core/logging/repo_logger.dart';
import 'package:likha/core/sync/mutation_result.dart';
import 'package:likha/core/sync/sync_queue.dart';
import 'package:likha/core/utils/typedef.dart';
import 'package:likha/data/datasources/local/grading/grading_local_datasource.dart';
import 'package:likha/data/models/grading/grade_score_model.dart';

ResultFuture<MutationResult<void>> saveScores(
  GradingLocalDataSource localDataSource,
  SyncQueue syncQueue, {
  required String gradeItemId,
  required List<Map<String, dynamic>> scores,
}) async {
  RepoLogger.instance.log('saveScores() - gradeItemId=$gradeItemId, scoresCount=${scores.length}');
  try {
    if (gradeItemId.isEmpty) {
      RepoLogger.instance.warn('saveScores() - Empty grade item ID, skipping sync enqueue');
      return const Right(MutationResult(entity: null, status: SyncStatus.pending));
    }

    final now = DateTime.now();
    final queueEntryId = const Uuid().v4();
    final nowStr = now.toIso8601String();

    final models = scores.map((s) {
      final scoreId = s['id'] as String? ?? const Uuid().v4();
      final studentId = s['student_id'] as String;
      final scoreValue = (s['score'] as num).toDouble();
      final isAutoPopulated = s['is_auto_populated'] == true || s['is_auto_populated'] == 1;

      return GradeScoreModel(
        id: scoreId,
        gradeItemId: gradeItemId,
        studentId: studentId,
        score: scoreValue,
        isAutoPopulated: isAutoPopulated,
        overrideScore: null,
        createdAt: nowStr,
        updatedAt: nowStr,
        syncStatus: SyncStatus.pending.dbValue,
      );
    }).toList();

    RepoLogger.instance.log('saveScores() - Built ${models.length} score models: '
        '${models.map((m) => 'student=${m.studentId},score=${m.score},id=${m.id}').join(', ')}');

    final db = await localDataSource.localDatabase.database;
    RepoLogger.instance.log('saveScores() - Starting DB transaction for upsert + enqueue');
    await db.transaction((txn) async {
      RepoLogger.instance.log('saveScores() - Calling upsertScoresByItem for gradeItemId=$gradeItemId');
      await localDataSource.upsertScoresByItem(gradeItemId, models, txn: txn);
      RepoLogger.instance.log('saveScores() - upsertScoresByItem completed, now enqueuing sync entry');
      await syncQueue.enqueue(
        SyncQueueEntry(
          id: queueEntryId,
          entityType: SyncEntityType.gradeScore,
          operation: SyncOperation.saveScores,
          payload: {
            'grade_item_id': gradeItemId,
            'scores': models.map((s) => s.toMap()).toList(),
          },
          status: SyncStatus.pending,
          retryCount: 0,
          maxRetries: 5,
          createdAt: now,
        ),
        txn: txn,
      );
    });

    RepoLogger.instance.log('saveScores() - Transaction committed successfully, queueEntryId=$queueEntryId');
    return const Right(MutationResult(entity: null, status: SyncStatus.pending));
  } catch (e, st) {
    RepoLogger.instance.error('saveScores() - FAILED: $e', st);
    return Left(ServerFailure(e.toString()));
  }
}
