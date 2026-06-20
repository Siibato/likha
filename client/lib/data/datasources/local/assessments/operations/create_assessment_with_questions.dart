import 'package:likha/core/database/db_schema.dart';
import 'package:likha/core/database/local_database.dart';
import 'package:likha/core/errors/exceptions.dart';
import 'package:likha/data/models/assessments/question_model.dart';
import 'package:sqflite_sqlcipher/sqflite.dart';
import 'package:uuid/uuid.dart';

Future<String> createAssessmentWithQuestions(
  LocalDatabase localDatabase,
  String classId,
  String title,
  String? description,
  int timeLimitMinutes,
  String openAt,
  String closeAt,
  bool? showResultsImmediately,
  List<QuestionModel> questions,
  bool isPublished,
  String? linkedTosId,
  int? quarter,
  String? component, {
  String? id,
  Transaction? txn,
}) async {
  try {
    final db = await localDatabase.database;
    final assessmentId = id ?? const Uuid().v4();
    final now = DateTime.now();

    Future<void> doInsert(Transaction t) async {
      await t.insert(
        DbTables.assessments,
        {
          CommonCols.id: assessmentId,
          AssessmentsCols.classId: classId,
          AssessmentsCols.title: title,
          if (description != null) AssessmentsCols.description: description,
          AssessmentsCols.timeLimitMinutes: timeLimitMinutes,
          AssessmentsCols.openAt: openAt,
          AssessmentsCols.closeAt: closeAt,
          AssessmentsCols.showResultsImmediately: (showResultsImmediately ?? false) ? 1 : 0,
          AssessmentsCols.resultsReleased: 0,
          AssessmentsCols.isPublished: isPublished ? 1 : 0,
          AssessmentsCols.orderIndex: 0,
          if (linkedTosId != null) AssessmentsCols.tosId: linkedTosId,
          if (quarter != null) AssessmentsCols.termNumber: quarter,
          if (component != null) AssessmentsCols.component: component,
          CommonCols.createdAt: now.toIso8601String(),
          CommonCols.updatedAt: now.toIso8601String(),
          CommonCols.cachedAt: now.toIso8601String(),
          CommonCols.syncStatus: 'pending',
        },
      );

      for (final question in questions) {
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
            CommonCols.createdAt: now.toIso8601String(),
            CommonCols.updatedAt: now.toIso8601String(),
            CommonCols.cachedAt: now.toIso8601String(),
            CommonCols.syncStatus: 'pending',
          },
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
                CommonCols.cachedAt: now.toIso8601String(),
                CommonCols.syncStatus: 'synced',
              },
            );
          }
        }

        if (question.correctAnswers != null && question.correctAnswers!.isNotEmpty) {
          final answerKeyId = const Uuid().v4();
          await t.insert(
            DbTables.answerKeys,
            {
              CommonCols.id: answerKeyId,
              AnswerKeysCols.questionId: question.id,
              AnswerKeysCols.itemType: DbValues.itemTypeCorrectAnswer,
              CommonCols.cachedAt: now.toIso8601String(),
              CommonCols.syncStatus: 'synced',
            },
          );

          for (final answer in question.correctAnswers!) {
            await t.insert(
              DbTables.answerKeyAcceptableAnswers,
              {
                CommonCols.id: answer.id,
                AnswerKeyAcceptableAnswersCols.answerKeyId: answerKeyId,
                AnswerKeyAcceptableAnswersCols.answerText: answer.answerText,
                CommonCols.cachedAt: now.toIso8601String(),
                CommonCols.syncStatus: 'synced',
              },
            );
          }
        }

        if (question.enumerationItems != null && question.enumerationItems!.isNotEmpty) {
          for (final enumItem in question.enumerationItems!) {
            final answerKeyId = const Uuid().v4();
            await t.insert(
              DbTables.answerKeys,
              {
                CommonCols.id: answerKeyId,
                AnswerKeysCols.questionId: question.id,
                AnswerKeysCols.itemType: DbValues.itemTypeEnumerationItem,
                CommonCols.cachedAt: now.toIso8601String(),
                CommonCols.syncStatus: 'synced',
              },
            );

            for (final acceptableAnswer in enumItem.acceptableAnswers) {
              await t.insert(
                DbTables.answerKeyAcceptableAnswers,
                {
                  CommonCols.id: acceptableAnswer.id,
                  AnswerKeyAcceptableAnswersCols.answerKeyId: answerKeyId,
                  AnswerKeyAcceptableAnswersCols.answerText: acceptableAnswer.answerText,
                  CommonCols.cachedAt: now.toIso8601String(),
                  CommonCols.syncStatus: 'synced',
                },
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

    return assessmentId;
  } catch (e) {
    throw CacheException('Failed to create assessment with questions locally: $e');
  }
}
