import 'package:dartz/dartz.dart';
import 'package:likha/core/errors/exceptions.dart';
import 'package:likha/core/errors/failures.dart';
import 'package:likha/core/utils/typedef.dart';
import 'package:likha/core/sync/sync_queue.dart';
import 'package:likha/domain/assessments/entities/question.dart';
import 'package:likha/data/repositories/assessments/assessment_repository_base.dart';
import 'package:uuid/uuid.dart';

ResultFuture<Question> updateQuestion(
  AssessmentRepositoryBase base, {
  required String questionId,
  required Map<String, dynamic> data,
}) async {
  try {
    if (!base.serverReachabilityService.isServerReachable) {
      final currentQuestion = await base.localDataSource.getCachedQuestion(questionId);
      if (currentQuestion == null) {
        return const Left(ServerFailure('Question not found in local cache'));
      }

      await base.localDataSource.updateQuestion(
        questionId: questionId,
        updates: data,
      );

      await base.syncQueue.enqueue(SyncQueueEntry(
        id: const Uuid().v4(),
        entityType: SyncEntityType.question,
        operation: SyncOperation.update,
        payload: {'id': questionId, ...data},
        status: SyncStatus.pending,
        retryCount: 0,
        maxRetries: 5,
        createdAt: DateTime.now(),
      ));

      return Right(Question(
        id: questionId,
        assessmentId: currentQuestion.assessmentId,
        questionType:
            data['question_type'] as String? ?? currentQuestion.questionType,
        questionText:
            data['question_text'] as String? ?? currentQuestion.questionText,
        points: data['points'] as int? ?? currentQuestion.points,
        orderIndex:
            data['order_index'] as int? ?? currentQuestion.orderIndex,
        isMultiSelect:
            data['is_multi_select'] as bool? ?? currentQuestion.isMultiSelect,
        needsSync: true,
        cachedAt: DateTime.now(),
      ));
    }

    final result = await base.remoteDataSource.updateQuestion(
      questionId: questionId,
      data: data,
    );
    await base.localDataSource.updateQuestion(
      questionId: questionId,
      updates: data,
      isOfflineMutation: false,  // mark as synced — no re-sync needed
    );
    return Right(result);
  } on ServerException catch (e) {
    return Left(ServerFailure(e.message, statusCode: e.statusCode));
  } on NetworkException catch (e) {
    return Left(NetworkFailure(e.message));
  } catch (e) {
    return Left(ServerFailure(e.toString()));
  }
}
