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
}) async {
  try {
    final db = await localDatabase.database;

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

    await db.transaction((txn) async {
      for (final question in questions) {
        final now = DateTime.now().toIso8601String();
        await txn.delete(DbTables.answerKeys, where: '${AnswerKeysCols.questionId} = ?', whereArgs: [question.id]);
        await txn.delete(DbTables.questionChoices, where: '${QuestionChoicesCols.questionId} = ?', whereArgs: [question.id]);

        await txn.insert(
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
            CommonCols.needsSync: isServerConfirmed ? 0 : 1,
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );

        if (question.choices != null) {
          for (final choice in question.choices!) {
            await txn.insert(
              DbTables.questionChoices,
              {
                CommonCols.id: choice.id,
                QuestionChoicesCols.questionId: question.id,
                QuestionChoicesCols.choiceText: choice.choiceText,
                QuestionChoicesCols.isCorrect: choice.isCorrect ? 1 : 0,
                QuestionChoicesCols.orderIndex: choice.orderIndex,
                CommonCols.cachedAt: now,
                CommonCols.needsSync: 0,
              },
              conflictAlgorithm: ConflictAlgorithm.replace,
            );
          }
        }

        if (question.correctAnswers != null && question.correctAnswers!.isNotEmpty) {
          final answerKeyId = '${question.id}_correct_key';
          await txn.insert(
            DbTables.answerKeys,
            {
              CommonCols.id: answerKeyId,
              AnswerKeysCols.questionId: question.id,
              AnswerKeysCols.itemType: DbValues.itemTypeCorrectAnswer,
              CommonCols.cachedAt: now,
              CommonCols.needsSync: 0,
            },
            conflictAlgorithm: ConflictAlgorithm.replace,
          );

          for (final answer in question.correctAnswers!) {
            await txn.insert(
              DbTables.answerKeyAcceptableAnswers,
              {
                CommonCols.id: answer.id,
                AnswerKeyAcceptableAnswersCols.answerKeyId: answerKeyId,
                AnswerKeyAcceptableAnswersCols.answerText: answer.answerText,
                CommonCols.cachedAt: now,
                CommonCols.needsSync: 0,
              },
              conflictAlgorithm: ConflictAlgorithm.replace,
            );
          }
        }

        if (question.enumerationItems != null && question.enumerationItems!.isNotEmpty) {
          for (final enumItem in question.enumerationItems!) {
            final answerKeyId = enumItem.id;
            await txn.insert(
              DbTables.answerKeys,
              {
                CommonCols.id: answerKeyId,
                AnswerKeysCols.questionId: question.id,
                AnswerKeysCols.itemType: DbValues.itemTypeEnumerationItem,
                CommonCols.cachedAt: now,
                CommonCols.needsSync: 0,
              },
              conflictAlgorithm: ConflictAlgorithm.replace,
            );

            for (final acceptableAnswer in enumItem.acceptableAnswers) {
              await txn.insert(
                DbTables.answerKeyAcceptableAnswers,
                {
                  CommonCols.id: acceptableAnswer.id,
                  AnswerKeyAcceptableAnswersCols.answerKeyId: answerKeyId,
                  AnswerKeyAcceptableAnswersCols.answerText: acceptableAnswer.answerText,
                  CommonCols.cachedAt: now,
                  CommonCols.needsSync: 0,
                },
                conflictAlgorithm: ConflictAlgorithm.replace,
              );
            }
          }
        }
      }
    });
  } catch (e) {
    throw CacheException('Failed to cache questions: $e');
  }
}
