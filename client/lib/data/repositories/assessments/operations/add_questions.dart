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
import 'package:likha/domain/assessments/entities/question.dart';
import 'package:likha/data/models/assessments/question_model.dart'
    show QuestionModel, ChoiceModel, CorrectAnswerModel, EnumerationItemModel, EnumerationItemAnswerModel;
import 'package:uuid/uuid.dart';

ResultFuture<MutationResult<List<Question>>> addQuestions(
  AssessmentLocalDataSource localDataSource,
  SyncQueue syncQueue,
  AssessmentRemoteDataSource remoteDataSource, {
  required String assessmentId,
  required List<Map<String, dynamic>> questions,
}) async {
  try {
    final now = DateTime.now();
    final queueEntryId = const Uuid().v4();

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

    final payloadQuestions = List.generate(questionModels.length, (i) {
      final q = questions[i];
      final model = questionModels[i];
      final payload = {...q, 'id': model.id};

      if (model.choices != null && q['choices'] is List) {
        final originalChoices = q['choices'] as List;
        payload['choices'] = List.generate(
          originalChoices.length,
          (j) => {...originalChoices[j], 'id': model.choices![j].id},
        );
      }

      if (model.correctAnswers != null && q['correct_answers'] is List) {
        final originalAnswers = q['correct_answers'] as List;
        payload['correct_answers'] = List.generate(
          originalAnswers.length,
          (j) => {...(originalAnswers[j] is String ? {'answer_text': originalAnswers[j]} : originalAnswers[j]), 'id': model.correctAnswers![j].id},
        );
      }

      if (model.enumerationItems != null && q['enumeration_items'] is List) {
        final originalItems = q['enumeration_items'] as List;
        payload['enumeration_items'] = List.generate(
          originalItems.length,
          (j) {
            final origItem = originalItems[j];
            final enumItem = model.enumerationItems![j];
            final item = {...origItem, 'id': enumItem.id};
            final answers = enumItem.acceptableAnswers;
            item['acceptable_answers'] = List.generate(
              answers.length,
              (k) => {'id': answers[k].id, 'answer_text': answers[k].answerText},
            );
            return item;
          },
        );
      }

      return payload;
    });

    final payload = {
      'assessment_id': assessmentId,
      'questions': payloadQuestions,
    };

    final db = await localDataSource.localDatabase.database;
    await db.transaction((txn) async {
      await localDataSource.cacheQuestions(assessmentId, questionModels, txn: txn);
      await syncQueue.enqueue(
        SyncQueueEntry(
          id: queueEntryId,
          entityType: SyncEntityType.question,
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

    fireRemoteWrite<List<QuestionModel>>(
      remote: () => remoteDataSource.addQuestions(
        assessmentId: assessmentId,
        questions: payloadQuestions,
        idempotencyKey: queueEntryId,
      ),
      onSuccess: (serverQuestions) async {
        final db = await localDataSource.localDatabase.database;
        for (final q in questionModels) {
          await db.update(
            DbTables.assessmentQuestions,
            {CommonCols.syncStatus: SyncStatus.synced.dbValue},
            where: '${CommonCols.id} = ?',
            whereArgs: [q.id],
          );
        }
        await syncQueue.markSucceeded(queueEntryId);
      },
      onError: (error) async {
        if (error is NetworkException) {
          return;
        }
        final db = await localDataSource.localDatabase.database;
        for (final q in questionModels) {
          await db.update(
            DbTables.assessmentQuestions,
            {CommonCols.syncStatus: SyncStatus.failed.dbValue},
            where: '${CommonCols.id} = ?',
            whereArgs: [q.id],
          );
        }
        await syncQueue.markFailed(queueEntryId, error.toString());
      },
    );

    return Right(MutationResult(entity: questionModels, status: SyncStatus.pending));
  } catch (e) {
    return Left(ServerFailure(e.toString()));
  }
}
