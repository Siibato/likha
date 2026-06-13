import 'package:dartz/dartz.dart';
import 'package:likha/core/errors/exceptions.dart';
import 'package:likha/core/errors/failures.dart';
import 'package:likha/core/utils/typedef.dart';
import 'package:likha/domain/assessments/entities/assessment.dart';
import 'package:likha/data/models/assessments/question_model.dart'
    show QuestionModel, ChoiceModel, CorrectAnswerModel, EnumerationItemModel, EnumerationItemAnswerModel;
import 'package:uuid/uuid.dart';
import 'package:likha/core/network/server_reachability_service.dart';
import 'package:likha/data/datasources/local/assessments/assessment_local_datasource.dart';
import 'package:likha/data/datasources/remote/assessments/assessment_remote_datasource.dart';

ResultFuture<Assessment> createAssessment(
  ServerReachabilityService serverReachabilityService,
AssessmentLocalDataSource localDataSource,
AssessmentRemoteDataSource remoteDataSource, {
  required String classId,
  required String title,
  String? description,
  required int timeLimitMinutes,
  required String openAt,
  required String closeAt,
  bool? showResultsImmediately,
  bool isPublished = false,
  List<Map<String, dynamic>>? questions,
  int? gradingPeriodNumber,
  String? component,
  String? tosId,
}) async {
  try {
    if (!serverReachabilityService.isServerReachable) {
      final now = DateTime.now();

      if (questions != null && questions.isNotEmpty) {
        final questionModels = questions.map((q) {
          final id = const Uuid().v4();
          return QuestionModel(
            id: id,
            assessmentId: '', // Will be set by createAssessmentWithQuestions
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

        final assessmentId = await localDataSource.createAssessmentWithQuestions(
          classId: classId,
          title: title,
          description: description,
          timeLimitMinutes: timeLimitMinutes,
          openAt: openAt,
          closeAt: closeAt,
          showResultsImmediately: showResultsImmediately,
          isPublished: isPublished,
          questions: questionModels,
          linkedTosId: tosId,
          quarter: gradingPeriodNumber,
          component: component,
        );

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
          tosId: tosId,
          gradingPeriodNumber: gradingPeriodNumber,
          component: component,
          createdAt: now,
          updatedAt: now,
        ));
      }

      final assessmentId = await localDataSource.createAssessment(
        classId: classId,
        title: title,
        description: description,
        timeLimitMinutes: timeLimitMinutes,
        openAt: openAt,
        closeAt: closeAt,
        showResultsImmediately: showResultsImmediately,
        isPublished: isPublished,
        tosId: tosId,
        gradingPeriodNumber: gradingPeriodNumber,
        component: component,
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
        tosId: tosId,
        gradingPeriodNumber: gradingPeriodNumber,
        component: component,
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
        if (isPublished && questions != null && questions.isNotEmpty)
          'questions': questions,
        if (gradingPeriodNumber != null) 'grading_period_number': gradingPeriodNumber,
        if (component != null) 'component': component,
        if (tosId != null) 'tos_id': tosId,
      },
    );

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
