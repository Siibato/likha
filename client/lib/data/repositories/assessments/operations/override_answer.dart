import 'package:dartz/dartz.dart';
import 'package:likha/core/errors/failures.dart';
import 'package:likha/core/sync/mutation_result.dart';
import 'package:likha/core/sync/sync_queue.dart';
import 'package:likha/core/utils/typedef.dart';
import 'package:likha/domain/assessments/entities/submission.dart';
import 'package:uuid/uuid.dart';
import 'package:likha/data/datasources/local/assessments/assessment_local_datasource.dart';

ResultFuture<MutationResult<SubmissionAnswer>> overrideAnswer(
  AssessmentLocalDataSource localDataSource,
  SyncQueue syncQueue, {
  required String answerId,
  required bool isCorrect,
  double? points,
}) async {
  try {
    final now = DateTime.now();

    final db = await localDataSource.localDatabase.database;
    await db.transaction((txn) async {
      await localDataSource.overrideAnswer(
        answerId: answerId,
        isCorrect: isCorrect,
        points: points,
        txn: txn,
      );
      await syncQueue.enqueue(
        SyncQueueEntry(
          id: const Uuid().v4(),
          entityType: SyncEntityType.assessmentSubmission,
          operation: SyncOperation.overrideAnswer,
          payload: {
            'answer_id': answerId,
            'is_correct': isCorrect,
            if (points != null) 'points': points,
          },
          status: SyncStatus.pending,
          retryCount: 0,
          maxRetries: 5,
          createdAt: now,
        ),
        txn: txn,
      );
    });

    final optimisticModel = SubmissionAnswer(
      id: answerId,
      questionId: '',
      questionText: '',
      questionType: '',
      points: 0,
      isOverrideCorrect: isCorrect,
      pointsAwarded: points ?? (isCorrect ? 0 : 0),
    );

    return Right(MutationResult(entity: optimisticModel, status: SyncStatus.pending));
  } catch (e) {
    return Left(ServerFailure(e.toString()));
  }
}
