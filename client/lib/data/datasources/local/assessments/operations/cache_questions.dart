import 'package:likha/core/errors/exceptions.dart';
import 'package:likha/core/database/db_schema.dart';
import 'package:likha/core/database/local_database.dart';
import 'package:likha/data/models/assessments/question_model.dart';
import 'package:sqflite_sqlcipher/sqflite.dart';

Future<void> cacheQuestions(
  LocalDatabase localDatabase,
  String assessmentId,
  List<QuestionModel> questions, {
  bool isServerConfirmed = false,
  Transaction? txn,
}) async {
  try {
    final db = await localDatabase.database;

    if (txn == null) {
      final assessmentExists = await db.rawQuery(
        'SELECT id FROM ${DbTables.assessments} WHERE id = ? LIMIT 1',
        [assessmentId],
      );

      if (assessmentExists.isEmpty) {
        throw CacheException(
          'Assessment with ID $assessmentId not found in database. '
          'Cannot insert questions without a valid assessment reference.'
        );
      }
    }

    Future<void> doInsert(Transaction t) async {
      for (final question in questions) {
        final now = DateTime.now().toIso8601String();
        await t.delete(DbTables.answerKeys, where: '${AnswerKeysCols.questionId} = ?', whereArgs: [question.id]);
        await t.delete(DbTables.questionChoices, where: '${QuestionChoicesCols.questionId} = ?', whereArgs: [question.id]);

        await t.insert(
          DbTables.assessmentQuestions,
          {
            CommonCols.id: question.id,
            AssessmentQuestionsCols.assessmentId: assessmentId,
            AssessmentQuestionsCols.questionType: question.questionType,
            AssessmentQuestionsCols.questionText: question.questionText,
            AssessmentQuestionsCols.points: question.points,
            AssessmentQuestionsCols.orderIndex: question.orderIndex,
            AssessmentQuestionsCols.isMultiSelect: question.isMultiSelect ? 1 : 0,
            CommonCols.createdAt: question.createdAt?.toIso8601String() ?? now,
            CommonCols.updatedAt: question.updatedAt?.toIso8601String() ?? now,
            CommonCols.cachedAt: now,
            CommonCols.syncStatus: isServerConfirmed ? 'synced' : 'pending',
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );

        if (question.choices != null) {
          for (final choice in question.choices!) {
            await t.insert(
              DbTables.questionChoices,
              {
                CommonCols.id: choice.id,
                QuestionChoicesCols.questionId: question.id,
                QuestionChoicesCols.choiceText: choice.choiceText,
                QuestionChoicesCols.isCorrect: choice.isCorrect ? 1 : 0,
                QuestionChoicesCols.orderIndex: choice.orderIndex,
                CommonCols.cachedAt: now,
                CommonCols.syncStatus: 'synced',
              },
              conflictAlgorithm: ConflictAlgorithm.replace,
            );
          }
        }

        if (question.correctAnswers != null && question.correctAnswers!.isNotEmpty) {
          final answerKeyId = '${question.id}_correct_key';
          await t.insert(
            DbTables.answerKeys,
            {
              CommonCols.id: answerKeyId,
              AnswerKeysCols.questionId: question.id,
              AnswerKeysCols.itemType: DbValues.itemTypeCorrectAnswer,
              CommonCols.cachedAt: now,
              CommonCols.syncStatus: 'synced',
            },
            conflictAlgorithm: ConflictAlgorithm.replace,
          );

          for (final answer in question.correctAnswers!) {
            await t.insert(
              DbTables.answerKeyAcceptableAnswers,
              {
                CommonCols.id: answer.id,
                AnswerKeyAcceptableAnswersCols.answerKeyId: answerKeyId,
                AnswerKeyAcceptableAnswersCols.answerText: answer.answerText,
                CommonCols.cachedAt: now,
                CommonCols.syncStatus: 'synced',
              },
              conflictAlgorithm: ConflictAlgorithm.replace,
            );
          }
        }

        if (question.enumerationItems != null && question.enumerationItems!.isNotEmpty) {
          for (final enumItem in question.enumerationItems!) {
            final answerKeyId = enumItem.id;
            await t.insert(
              DbTables.answerKeys,
              {
                CommonCols.id: answerKeyId,
                AnswerKeysCols.questionId: question.id,
                AnswerKeysCols.itemType: DbValues.itemTypeEnumerationItem,
                CommonCols.cachedAt: now,
                CommonCols.syncStatus: 'synced',
              },
              conflictAlgorithm: ConflictAlgorithm.replace,
            );

            for (final acceptableAnswer in enumItem.acceptableAnswers) {
              await t.insert(
                DbTables.answerKeyAcceptableAnswers,
                {
                  CommonCols.id: acceptableAnswer.id,
                  AnswerKeyAcceptableAnswersCols.answerKeyId: answerKeyId,
                  AnswerKeyAcceptableAnswersCols.answerText: acceptableAnswer.answerText,
                  CommonCols.cachedAt: now,
                  CommonCols.syncStatus: 'synced',
                },
                conflictAlgorithm: ConflictAlgorithm.replace,
              );
            }
          }
        }
      }
    }

    if (txn != null) {
      await doInsert(txn);
    } else {
      await db.transaction((innerTxn) async {
        await doInsert(innerTxn);
      });
    }
  } catch (e) {
    throw CacheException('Failed to cache questions: $e');
  }
}
