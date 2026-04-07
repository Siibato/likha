import 'package:likha/core/errors/exceptions.dart';
import 'package:likha/core/sync/sync_queue.dart';
import 'package:likha/data/models/assessments/assessment_model.dart';
import 'package:likha/data/models/assessments/question_model.dart';
import 'package:likha/core/database/db_schema.dart';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';
import '../assessment_local_datasource_base.dart';

mixin AssessmentCacheMixin on AssessmentLocalDataSourceBase {
  @override
  Future<void> cacheAssessments(List<AssessmentModel> assessments) async {
    try {
      final db = await localDatabase.database;
      await db.transaction((txn) async {
        for (final assessment in assessments) {
          final map = assessment.toMap();
          map[CommonCols.cachedAt] = DateTime.now().toIso8601String();
          map[CommonCols.needsSync] = 0;
          // Use update-first pattern to avoid CASCADE DELETE on assessment_submissions
          final assessmentId = map[CommonCols.id] as String;
          final updated = await txn.update(DbTables.assessments, map, where: '${CommonCols.id} = ?', whereArgs: [assessmentId]);
          if (updated == 0) {
            await txn.insert(DbTables.assessments, map);
          }
        }
      });
    } catch (e) {
      throw CacheException('Failed to cache assessments: $e');
    }
  }

  @override
  Future<void> cacheAssessmentDetail(AssessmentModel assessment, List<QuestionModel> questions) async {
    try {
      final db = await localDatabase.database;
      await db.transaction((txn) async {
        final assessmentMap = assessment.toMap();
        assessmentMap[CommonCols.cachedAt] = DateTime.now().toIso8601String();
        assessmentMap[CommonCols.needsSync] = 0;
        // Use update-first pattern to avoid CASCADE DELETE on assessment_submissions
        final assessmentId = assessmentMap[CommonCols.id] as String;
        final updated = await txn.update(DbTables.assessments, assessmentMap, where: '${CommonCols.id} = ?', whereArgs: [assessmentId]);
        if (updated == 0) {
          await txn.insert(DbTables.assessments, assessmentMap);
        }

        for (final question in questions) {
          final now = DateTime.now().toIso8601String();
          // Delete stale child rows before re-inserting (prevents orphan accumulation)
          await txn.delete(DbTables.answerKeys, where: '${AnswerKeysCols.questionId} = ?', whereArgs: [question.id]);
          await txn.delete(DbTables.questionChoices, where: '${QuestionChoicesCols.questionId} = ?', whereArgs: [question.id]);

          // Insert assessment_questions (v18 - renamed from 'questions')
          await txn.insert(
            DbTables.assessmentQuestions,
            {
              CommonCols.id: question.id,
              AssessmentQuestionsCols.assessmentId: assessment.id,
              AssessmentQuestionsCols.questionType: question.questionType,
              AssessmentQuestionsCols.questionText: question.questionText,
              AssessmentQuestionsCols.points: question.points,
              AssessmentQuestionsCols.orderIndex: question.orderIndex,
              AssessmentQuestionsCols.isMultiSelect: question.isMultiSelect ? 1 : 0,
              CommonCols.createdAt: question.createdAt?.toIso8601String() ?? now,
              CommonCols.updatedAt: question.updatedAt?.toIso8601String() ?? now,
              CommonCols.cachedAt: now,
              CommonCols.needsSync: 0,
            },
            conflictAlgorithm: ConflictAlgorithm.replace,
          );

          // Normalize choices into question_choices table
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

          // Normalize correct answers into answer_keys and answer_key_acceptable_answers
          if (question.correctAnswers != null && question.correctAnswers!.isNotEmpty) {
            // Use stable ID for correctAnswers (composite ID)
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

            // Insert acceptable answers
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

          // Normalize enumeration items into answer_keys and answer_key_acceptable_answers
          if (question.enumerationItems != null && question.enumerationItems!.isNotEmpty) {
            for (final enumItem in question.enumerationItems!) {
              // Use server ID for enumeration items
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

              // Insert acceptable answers for this enumeration item
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
      throw CacheException('Failed to cache assessment detail: $e');
    }
  }

  @override
  Future<void> cacheQuestions(
    String assessmentId,
    List<QuestionModel> questions, {
    bool isServerConfirmed = false,
  }) async {
    try {
      final db = await localDatabase.database;

      // Verify assessment exists before inserting questions (FK constraint check)
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
          // Delete stale child rows before re-inserting (prevents orphan accumulation)
          await txn.delete(DbTables.answerKeys, where: '${AnswerKeysCols.questionId} = ?', whereArgs: [question.id]);
          await txn.delete(DbTables.questionChoices, where: '${QuestionChoicesCols.questionId} = ?', whereArgs: [question.id]);

          // Insert into assessment_questions (v18 - renamed from 'questions')
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

          // Normalize choices
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

          // Normalize correct answers
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

          // Normalize enumeration items
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

  @override
  Future<void> releaseResultsLocally({required String assessmentId}) async {
    try {
      final db = await localDatabase.database;
      final now = DateTime.now();
      await db.transaction((txn) async {
        await txn.update(
          DbTables.assessments,
          {
            AssessmentsCols.resultsReleased: 1,
            CommonCols.needsSync: 1,
            CommonCols.updatedAt: now.toIso8601String(),
            CommonCols.cachedAt: now.toIso8601String(),
          },
          where: '${CommonCols.id} = ?',
          whereArgs: [assessmentId],
        );
        await syncQueue.enqueue(SyncQueueEntry(
          id: const Uuid().v4(),
          entityType: SyncEntityType.assessment,
          operation: SyncOperation.releaseResults,
          payload: {'id': assessmentId},
          status: SyncStatus.pending,
          retryCount: 0,
          maxRetries: 3,
          createdAt: now,
        ), txn: txn);
      });
    } catch (e) {
      throw CacheException('Failed to release results locally: $e');
    }
  }

  @override
  Future<void> deleteAssessmentLocally({required String assessmentId}) async {
    try {
      final db = await localDatabase.database;
      await db.update(
        DbTables.assessments,
        {
          CommonCols.deletedAt: DateTime.now().toIso8601String(),
          CommonCols.needsSync: 1,
          CommonCols.updatedAt: DateTime.now().toIso8601String(),
        },
        where: '${CommonCols.id} = ?',
        whereArgs: [assessmentId],
      );
    } catch (e) {
      throw CacheException('Failed to delete assessment locally: $e');
    }
  }

  @override
  Future<void> clearAllCache() async {
    try {
      final db = await localDatabase.database;
      await db.delete(DbTables.assessments);
      await db.delete(DbTables.assessmentQuestions);
      await db.delete(DbTables.questionChoices);
      await db.delete(DbTables.answerKeys);
      await db.delete(DbTables.answerKeyAcceptableAnswers);
      await db.delete(DbTables.submissionAnswers);
      await db.delete(DbTables.submissionAnswerItems);
      await db.delete(DbTables.assessmentSubmissions);
    } catch (e) {
      throw CacheException('Failed to clear assessment cache: $e');
    }
  }
}
