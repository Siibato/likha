import 'package:dartz/dartz.dart';
import 'package:likha/core/errors/exceptions.dart';
import 'package:likha/core/errors/failures.dart';
import 'package:likha/core/utils/typedef.dart';
import 'package:likha/core/sync/sync_queue.dart';
import 'package:likha/domain/assessments/entities/assessment.dart';
import 'package:likha/data/repositories/assessments/assessment_repository_base.dart';
import 'package:likha/data/models/assessments/question_model.dart'
    show QuestionModel, ChoiceModel, CorrectAnswerModel, EnumerationItemModel, EnumerationItemAnswerModel;
import 'package:uuid/uuid.dart';

mixin AssessmentCrudMixin on AssessmentRepositoryBase {
  @override
  ResultFuture<Assessment> createAssessment({
    required String classId,
    required String title,
    String? description,
    required int timeLimitMinutes,
    required String openAt,
    required String closeAt,
    bool? showResultsImmediately,
    bool isPublished = false,
    List<Map<String, dynamic>>? questions,
    int? quarter,
    String? component,
    bool? isDepartmentalExam,
  }) async {
    try {
      if (!serverReachabilityService.isServerReachable) {
        final now = DateTime.now();

        // When creating an assessment with questions (published or draft), use atomic creation method
        if (questions != null && questions.isNotEmpty) {
          // Convert questions to QuestionModel (same pattern as addQuestions)
          final questionModels = questions.map((q) {
            final id = const Uuid().v4();
            return QuestionModel(
              id: id,
              assessmentId: '', // Will be set by createAssessmentWithQuestionsLocally
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

          final assessmentId = await localDataSource.createAssessmentWithQuestionsLocally(
            classId: classId,
            title: title,
            description: description,
            timeLimitMinutes: timeLimitMinutes,
            openAt: openAt,
            closeAt: closeAt,
            showResultsImmediately: showResultsImmediately,
            isPublished: isPublished,
            questions: questionModels,
          );

          // Calculate totalPoints from questions
          int totalPoints = 0;
          for (final q in questions) {
            totalPoints += q['points'] as int? ?? 0;
          }

          return Right(Assessment(
            id: assessmentId,
            classId: classId,
            title: title,
            description: description,
            timeLimitMinutes: timeLimitMinutes,
            openAt: DateTime.parse(openAt),
            closeAt: DateTime.parse(closeAt),
            showResultsImmediately: showResultsImmediately ?? false,
            resultsReleased: false,
            isPublished: isPublished,
            orderIndex: 0,
            totalPoints: totalPoints,
            questionCount: questions.length,
            submissionCount: 0,
            createdAt: now,
            updatedAt: now,
          ));
        }

        // Draft path: create without questions
        final assessmentId = await localDataSource.createAssessmentLocally(
          classId: classId,
          title: title,
          description: description,
          timeLimitMinutes: timeLimitMinutes,
          openAt: openAt,
          closeAt: closeAt,
          showResultsImmediately: showResultsImmediately,
          isPublished: isPublished,
        );

        return Right(Assessment(
          id: assessmentId,
          classId: classId,
          title: title,
          description: description,
          timeLimitMinutes: timeLimitMinutes,
          openAt: DateTime.parse(openAt),
          closeAt: DateTime.parse(closeAt),
          showResultsImmediately: showResultsImmediately ?? false,
          resultsReleased: false,
          isPublished: isPublished,
          orderIndex: 0,
          totalPoints: 0,
          questionCount: 0,
          submissionCount: 0,
          createdAt: now,
          updatedAt: now,
        ));
      }

      final result = await remoteDataSource.createAssessment(
        classId: classId,
        data: {
          'title': title,
          if (description != null) 'description': description,
          'time_limit_minutes': timeLimitMinutes,
          'open_at': openAt,
          'close_at': closeAt,
          if (showResultsImmediately != null)
            'show_results_immediately': showResultsImmediately,
          if (isPublished) 'is_published': true,
          // NEW: include questions atomically when publishing
          if (isPublished && questions != null && questions.isNotEmpty)
            'questions': questions,
          if (quarter != null) 'quarter': quarter,
          if (component != null) 'component': component,
          if (isDepartmentalExam != null) 'is_departmental_exam': isDepartmentalExam,
        },
      );

      // Cache the assessment locally so subsequent operations (like addQuestions) can reference it
      await localDataSource.cacheAssessments([result]);

      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message, statusCode: e.statusCode));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  ResultFuture<Assessment> updateAssessment({
    required String assessmentId,
    String? title,
    String? description,
    int? timeLimitMinutes,
    String? openAt,
    String? closeAt,
    bool? showResultsImmediately,
  }) async {
    try {
      if (!serverReachabilityService.isServerReachable) {
        await syncQueue.enqueue(SyncQueueEntry(
          id: const Uuid().v4(),
          entityType: SyncEntityType.assessment,
          operation: SyncOperation.update,
          payload: {
            'id': assessmentId,
            if (title != null) 'title': title,
            if (description != null) 'description': description,
            if (timeLimitMinutes != null) 'time_limit_minutes': timeLimitMinutes,
            if (openAt != null) 'open_at': openAt,
            if (closeAt != null) 'close_at': closeAt,
            if (showResultsImmediately != null)
              'show_results_immediately': showResultsImmediately,
          },
          status: SyncStatus.pending,
          retryCount: 0,
          maxRetries: 5,
          createdAt: DateTime.now(),
        ));

        return Right(Assessment(
          id: assessmentId,
          classId: '',
          title: title ?? '',
          description: description,
          timeLimitMinutes: timeLimitMinutes ?? 0,
          openAt: openAt != null ? DateTime.parse(openAt) : DateTime.now(),
          closeAt: closeAt != null ? DateTime.parse(closeAt) : DateTime.now(),
          showResultsImmediately: showResultsImmediately ?? false,
          resultsReleased: false,
          isPublished: false,
          orderIndex: 0,
          totalPoints: 0,
          questionCount: 0,
          submissionCount: 0,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ));
      }

      final data = <String, dynamic>{
        if (title != null) 'title': title,
        if (description != null) 'description': description,
        if (timeLimitMinutes != null) 'time_limit_minutes': timeLimitMinutes,
        if (openAt != null) 'open_at': openAt,
        if (closeAt != null) 'close_at': closeAt,
        if (showResultsImmediately != null)
          'show_results_immediately': showResultsImmediately,
      };

      final result = await remoteDataSource.updateAssessment(
        assessmentId: assessmentId,
        data: data,
      );
      // Cache the updated assessment locally so changes persist across app restarts
      await localDataSource.cacheAssessments([result]);
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message, statusCode: e.statusCode));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  ResultVoid deleteAssessment({required String assessmentId}) async {
    try {
      if (!serverReachabilityService.isServerReachable) {
        await syncQueue.enqueue(SyncQueueEntry(
          id: const Uuid().v4(),
          entityType: SyncEntityType.assessment,
          operation: SyncOperation.delete,
          payload: {'id': assessmentId},
          status: SyncStatus.pending,
          retryCount: 0,
          maxRetries: 5,
          createdAt: DateTime.now(),
        ));
        await localDataSource.deleteAssessmentLocally(assessmentId: assessmentId);
        return const Right(null);
      }

      await remoteDataSource.deleteAssessment(assessmentId: assessmentId);
      await localDataSource.deleteAssessmentLocally(assessmentId: assessmentId);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message, statusCode: e.statusCode));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  ResultVoid reorderAllAssessments({
    required String classId,
    required List<String> assessmentIds,
  }) async {
    try {
      if (!serverReachabilityService.isServerReachable) {
        for (int i = 0; i < assessmentIds.length; i++) {
          await syncQueue.enqueue(SyncQueueEntry(
            id: const Uuid().v4(),
            entityType: SyncEntityType.assessment,
            operation: SyncOperation.update,
            payload: {'id': assessmentIds[i], 'order_index': i},
            status: SyncStatus.pending,
            retryCount: 0,
            maxRetries: 5,
            createdAt: DateTime.now(),
          ));
        }
        return const Right(null);
      }
      await remoteDataSource.reorderAllAssessments(
        classId: classId,
        assessmentIds: assessmentIds,
      );
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message, statusCode: e.statusCode));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}