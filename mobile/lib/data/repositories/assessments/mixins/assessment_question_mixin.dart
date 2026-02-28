import 'package:dartz/dartz.dart';
import 'package:likha/core/errors/exceptions.dart';
import 'package:likha/core/errors/failures.dart';
import 'package:likha/core/utils/typedef.dart';
import 'package:likha/core/sync/sync_queue.dart';
import 'package:likha/domain/assessments/entities/question.dart';
import 'package:likha/data/models/assessments/question_model.dart'
    show QuestionModel, ChoiceModel, CorrectAnswerModel, EnumerationItemModel, EnumerationItemAnswerModel;
import 'package:likha/data/repositories/assessments/assessment_repository_base.dart';
import 'package:uuid/uuid.dart';

mixin AssessmentQuestionMixin on AssessmentRepositoryBase {
  @override
  ResultFuture<List<Question>> addQuestions({
    required String assessmentId,
    required List<Map<String, dynamic>> questions,
  }) async {
    try {
      if (!serverReachabilityService.isServerReachable) {
        final questionModels = questions.map((q) {
          final id = const Uuid().v4();
          return QuestionModel(
            id: id,
            questionType: q['question_type'] as String,
            questionText: q['question_text'] as String,
            points: q['points'] as int,
            orderIndex: q['order_index'] as int? ?? 0,
            isMultiSelect: q['is_multi_select'] as bool? ?? false,
            choices: (q['choices'] as List?)?.map((c) => ChoiceModel(
                  id: const Uuid().v4(),
                  choiceText: c['choice_text'] as String,
                  isCorrect: c['is_correct'] as bool,
                  orderIndex: c['order_index'] as int,
                )).toList(),
            correctAnswers: (q['correct_answers'] as List?)?.map((a) =>
                CorrectAnswerModel(
                  id: const Uuid().v4(),
                  answerText:
                      a is String ? a : (a as Map)['answer_text'] as String,
                )).toList(),
            enumerationItems: (q['enumeration_items'] as List?)?.map((e) =>
                EnumerationItemModel(
                  id: const Uuid().v4(),
                  orderIndex: e['order_index'] as int,
                  acceptableAnswers: (e['acceptable_answers'] as List?)
                          ?.map((a) => EnumerationItemAnswerModel(
                                id: const Uuid().v4(),
                                answerText: a is String
                                    ? a
                                    : (a as Map)['answer_text'] as String,
                              ))
                          .toList() ??
                      const [],
                )).toList(),
          );
        }).toList();

        await localDataSource.cacheQuestions(questionModels);

        await syncQueue.enqueue(SyncQueueEntry(
          id: const Uuid().v4(),
          entityType: SyncEntityType.question,
          operation: SyncOperation.create,
          payload: {
            'assessment_id': assessmentId,
            'questions': questions,
          },
          status: SyncStatus.pending,
          retryCount: 0,
          maxRetries: 5,
          createdAt: DateTime.now(),
        ));

        return Right(questionModels);
      }

      final result = await remoteDataSource.addQuestions(
        assessmentId: assessmentId,
        questions: questions,
      );
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  ResultFuture<Question> updateQuestion({
    required String questionId,
    required Map<String, dynamic> data,
  }) async {
    try {
      if (!serverReachabilityService.isServerReachable) {
        await localDataSource.updateQuestionLocally(
          questionId: questionId,
          updates: data,
        );

        await syncQueue.enqueue(SyncQueueEntry(
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
          questionType: data['question_type'] as String? ?? '',
          questionText: data['question_text'] as String? ?? '',
          points: data['points'] as int? ?? 0,
          orderIndex: data['order_index'] as int? ?? 0,
          isMultiSelect: data['is_multi_select'] as bool? ?? false,
        ));
      }

      final result = await remoteDataSource.updateQuestion(
        questionId: questionId,
        data: data,
      );
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  ResultVoid deleteQuestion({required String questionId}) async {
    try {
      if (!serverReachabilityService.isServerReachable) {
        await localDataSource.deleteQuestionLocally(questionId: questionId);

        await syncQueue.enqueue(SyncQueueEntry(
          id: const Uuid().v4(),
          entityType: SyncEntityType.question,
          operation: SyncOperation.delete,
          payload: {'id': questionId},
          status: SyncStatus.pending,
          retryCount: 0,
          maxRetries: 5,
          createdAt: DateTime.now(),
        ));
        return const Right(null);
      }

      await remoteDataSource.deleteQuestion(questionId: questionId);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}