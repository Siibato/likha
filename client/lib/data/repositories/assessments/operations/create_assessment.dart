import 'package:dartz/dartz.dart';
import 'package:likha/core/database/db_schema.dart';
import 'package:likha/core/errors/exceptions.dart';
import 'package:likha/core/errors/failures.dart';
import 'package:likha/core/sync/mutation_result.dart';
import 'package:likha/core/sync/sync_queue.dart';
import 'package:likha/core/utils/remote_write.dart';
import 'package:likha/core/utils/typedef.dart';
import 'package:likha/data/datasources/local/assessments/assessment_local_datasource.dart';
import 'package:likha/data/datasources/remote/assessments/assessment_remote_datasource.dart';
import 'package:likha/data/models/assessments/assessment_model.dart';
import 'package:likha/data/models/assessments/question_model.dart'
    show QuestionModel, ChoiceModel, CorrectAnswerModel, EnumerationItemModel, EnumerationItemAnswerModel;
import 'package:likha/domain/assessments/entities/assessment.dart';
import 'package:uuid/uuid.dart';

ResultFuture<MutationResult<Assessment>> createAssessment(
  AssessmentLocalDataSource localDataSource,
  SyncQueue syncQueue,
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
    final now = DateTime.now();
    final assessmentId = const Uuid().v4();
    final queueEntryId = const Uuid().v4();

    int totalPoints = 0;
    int questionCount = 0;

    if (questions != null && questions.isNotEmpty) {
      questionCount = questions.length;
      final questionModels = questions.map((q) {
        final id = const Uuid().v4();
        return QuestionModel(
          id: id,
          assessmentId: assessmentId,
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

      for (final q in questions) {
        totalPoints += q['points'] as int? ?? 0;
      }

      final payload = {
        'id': assessmentId,
        'class_id': classId,
        'title': title,
        if (description != null) 'description': description,
        'time_limit_minutes': timeLimitMinutes,
        'open_at': openAt,
        'close_at': closeAt,
        if (showResultsImmediately != null) 'show_results_immediately': showResultsImmediately,
        'is_published': isPublished,
        if (gradingPeriodNumber != null) 'grading_period_number': gradingPeriodNumber,
        if (component != null) 'component': component,
        if (tosId != null) 'tos_id': tosId,
        'questions': questions,
      };

      final optimisticModel = AssessmentModel(
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
        questionCount: questionCount,
        submissionCount: 0,
        tosId: tosId,
        gradingPeriodNumber: gradingPeriodNumber,
        component: component,
        createdAt: now,
        updatedAt: now,
        syncStatus: SyncStatus.pending,
      );

      final db = await localDataSource.localDatabase.database;
      await db.transaction((txn) async {
        await localDataSource.createAssessmentWithQuestions(
          id: assessmentId,
          classId: classId,
          title: title,
          description: description,
          timeLimitMinutes: timeLimitMinutes,
          openAt: openAt,
          closeAt: closeAt,
          showResultsImmediately: showResultsImmediately,
          questions: questionModels,
          isPublished: isPublished,
          linkedTosId: tosId,
          quarter: gradingPeriodNumber,
          component: component,
          txn: txn,
        );
        await syncQueue.enqueue(
          SyncQueueEntry(
            id: queueEntryId,
            entityType: SyncEntityType.assessment,
            operation: SyncOperation.create,
            payload: payload,
            status: SyncStatus.pending,
            retryCount: 0,
            maxRetries: 5,
            createdAt: now,
          ),
          txn: txn,
        );
      });

      fireRemoteWrite<AssessmentModel>(
        remote: () => remoteDataSource.createAssessment(
          classId: classId,
          data: payload,
          idempotencyKey: queueEntryId,
        ),
        onSuccess: (serverModel) async {
          final db = await localDataSource.localDatabase.database;

          if (serverModel.id != assessmentId) {
            await db.update(
              DbTables.assessments,
              {CommonCols.id: serverModel.id},
              where: '${CommonCols.id} = ?',
              whereArgs: [assessmentId],
            );
            await db.update(
              DbTables.assessmentQuestions,
              {AssessmentQuestionsCols.assessmentId: serverModel.id},
              where: '${AssessmentQuestionsCols.assessmentId} = ?',
              whereArgs: [assessmentId],
            );
          }

          await db.update(
            DbTables.assessments,
            {CommonCols.syncStatus: SyncStatus.synced.dbValue},
            where: '${CommonCols.id} = ?',
            whereArgs: [serverModel.id],
          );
          await syncQueue.markSucceeded(queueEntryId);
        },
        onError: (error) async {
          if (error is NetworkException) {
            return;
          }

          final db = await localDataSource.localDatabase.database;
          await db.update(
            DbTables.assessments,
            {CommonCols.syncStatus: SyncStatus.failed.dbValue},
            where: '${CommonCols.id} = ?',
            whereArgs: [assessmentId],
          );
          await syncQueue.markFailed(queueEntryId, error.toString());
        },
      );

      return Right(MutationResult(entity: optimisticModel, status: SyncStatus.pending));
    }

    final payload = {
      'id': assessmentId,
      'class_id': classId,
      'title': title,
      if (description != null) 'description': description,
      'time_limit_minutes': timeLimitMinutes,
      'open_at': openAt,
      'close_at': closeAt,
      if (showResultsImmediately != null) 'show_results_immediately': showResultsImmediately,
      'is_published': isPublished,
      if (gradingPeriodNumber != null) 'grading_period_number': gradingPeriodNumber,
      if (component != null) 'component': component,
      if (tosId != null) 'tos_id': tosId,
    };

    final optimisticModel = AssessmentModel(
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
      questionCount: questionCount,
      submissionCount: 0,
      tosId: tosId,
      gradingPeriodNumber: gradingPeriodNumber,
      component: component,
      createdAt: now,
      updatedAt: now,
      syncStatus: SyncStatus.pending,
    );

    final db = await localDataSource.localDatabase.database;
    await db.transaction((txn) async {
      await localDataSource.createAssessment(
        id: assessmentId,
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
        txn: txn,
      );
      await syncQueue.enqueue(
        SyncQueueEntry(
          id: queueEntryId,
          entityType: SyncEntityType.assessment,
          operation: SyncOperation.create,
          payload: payload,
          status: SyncStatus.pending,
          retryCount: 0,
          maxRetries: 5,
          createdAt: now,
        ),
        txn: txn,
      );
    });

    fireRemoteWrite<AssessmentModel>(
      remote: () => remoteDataSource.createAssessment(
        classId: classId,
        data: payload,
        idempotencyKey: queueEntryId,
      ),
      onSuccess: (serverModel) async {
        final db = await localDataSource.localDatabase.database;

        if (serverModel.id != assessmentId) {
          await db.update(
            DbTables.assessments,
            {CommonCols.id: serverModel.id},
            where: '${CommonCols.id} = ?',
            whereArgs: [assessmentId],
          );
        }

        await db.update(
          DbTables.assessments,
          {CommonCols.syncStatus: SyncStatus.synced.dbValue},
          where: '${CommonCols.id} = ?',
          whereArgs: [serverModel.id],
        );
        await syncQueue.markSucceeded(queueEntryId);
      },
      onError: (error) async {
        if (error is NetworkException) {
          return;
        }

        final db = await localDataSource.localDatabase.database;
        await db.update(
          DbTables.assessments,
          {CommonCols.syncStatus: SyncStatus.failed.dbValue},
          where: '${CommonCols.id} = ?',
          whereArgs: [assessmentId],
        );
        await syncQueue.markFailed(queueEntryId, error.toString());
      },
    );

    return Right(MutationResult(entity: optimisticModel, status: SyncStatus.pending));
  } catch (e) {
    return Left(ServerFailure(e.toString()));
  }
}
