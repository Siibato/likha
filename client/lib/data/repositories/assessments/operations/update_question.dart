import 'package:dartz/dartz.dart';
import 'package:likha/core/errors/failures.dart';
import 'package:likha/core/sync/mutation_result.dart';
import 'package:likha/core/sync/sync_queue.dart';
import 'package:likha/core/utils/typedef.dart';
import 'package:likha/domain/assessments/entities/question.dart';
import 'package:uuid/uuid.dart';
import 'package:likha/data/datasources/local/assessments/assessment_local_datasource.dart';

ResultFuture<MutationResult<Question>> updateQuestion(
  AssessmentLocalDataSource localDataSource,
  SyncQueue syncQueue, {
  required String questionId,
  required Map<String, dynamic> data,
}) async {
  try {
    final currentQuestion = await localDataSource.getCachedQuestion(questionId);
    if (currentQuestion == null) {
      return const Left(ServerFailure('Question not found in local cache'));
    }

    final now = DateTime.now();
    final optimisticModel = Question(
      id: questionId,
      assessmentId: currentQuestion.assessmentId,
      questionType: data['question_type'] as String? ?? currentQuestion.questionType,
      questionText: data['question_text'] as String? ?? currentQuestion.questionText,
      points: data['points'] as int? ?? currentQuestion.points,
      orderIndex: data['order_index'] as int? ?? currentQuestion.orderIndex,
      isMultiSelect: data['is_multi_select'] as bool? ?? currentQuestion.isMultiSelect,
      syncStatus: SyncStatus.pending,
      cachedAt: now,
    );

    final db = await localDataSource.localDatabase.database;
    await db.transaction((txn) async {
      await localDataSource.updateQuestion(
        questionId: questionId,
        updates: data,
        txn: txn,
      );
      await syncQueue.enqueue(
        SyncQueueEntry(
          id: const Uuid().v4(),
          entityType: SyncEntityType.question,
          operation: SyncOperation.update,
          payload: {'id': questionId, ...data},
          status: SyncStatus.pending,
          retryCount: 0,
          maxRetries: 5,
          createdAt: now,
        ),
        txn: txn,
      );
    });

    return Right(MutationResult(entity: optimisticModel, status: SyncStatus.pending));
  } catch (e) {
    return Left(ServerFailure(e.toString()));
  }
}
