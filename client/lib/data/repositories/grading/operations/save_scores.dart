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
  GradingLocalDataSource localDataSource, {
  required String gradeItemId,
  required List<Map<String, dynamic>> scores,
}) async {
  RepoLogger.instance.log('saveScores() - gradeItemId=$gradeItemId, scoresCount=${scores.length}');
  try {
    // Basic validation of grade item ID format
    if (gradeItemId.isEmpty) {
      RepoLogger.instance.warn('saveScores() - Empty grade item ID, skipping sync enqueue');
      return Right(MutationResult(entity: null, status: SyncStatus.pending));
    }

    final now = DateTime.now().toIso8601String();

    // Save each score locally (optimistic)
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
        createdAt: now,
        updatedAt: now,
      );
    }).toList();

    // upsertScoresByItem enqueues the sync operation transactionally — no second enqueue needed.
    await localDataSource.upsertScoresByItem(gradeItemId, models);

    return Right(MutationResult(entity: null, status: SyncStatus.pending));
  } catch (e) {
    return Left(CacheFailure(e.toString()));
  }
}
