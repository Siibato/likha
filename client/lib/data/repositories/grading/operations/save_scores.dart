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

    final db = await localDataSource.localDatabase.database;
    await db.transaction((txn) async {
      await localDataSource.upsertScoresByItem(gradeItemId, models, txn: txn);
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

    return const Right(MutationResult(entity: null, status: SyncStatus.pending));
  } catch (e) {
    return Left(ServerFailure(e.toString()));
  }
}
