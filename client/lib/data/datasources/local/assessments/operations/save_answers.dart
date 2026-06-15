import 'dart:convert';
import 'package:likha/core/database/db_schema.dart';
import 'package:likha/core/database/local_database.dart';
import 'package:likha/core/errors/exceptions.dart';
import 'package:sqflite_sqlcipher/sqflite.dart';
import 'package:uuid/uuid.dart';

Future<void> saveAnswers(
  LocalDatabase localDatabase,
  String submissionId,
  String answersJson, {
  Transaction? txn,
}) async {
  try {
    final db = await localDatabase.database;
    final now = DateTime.now();
    final answers = jsonDecode(answersJson) as List<dynamic>;

    Future<void> doSave(Transaction t) async {
      await t.delete(DbTables.submissionAnswers, where: '${SubmissionAnswersCols.submissionId} = ?', whereArgs: [submissionId]);

      for (final answerData in answers) {
        final answer = answerData as Map<String, dynamic>;
        final answerId = answer['id'] as String? ?? const Uuid().v4();
        await t.insert(
          DbTables.submissionAnswers,
          {
            CommonCols.id: answerId,
            SubmissionAnswersCols.submissionId: submissionId,
            SubmissionAnswersCols.questionId: answer['question_id'] as String,
            SubmissionAnswersCols.points: 0,
            CommonCols.cachedAt: now.toIso8601String(),
            CommonCols.syncStatus: 'pending',
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );

        if (answer['selected_choices'] != null) {
          final choices = answer['selected_choices'] as List<dynamic>;
          for (final choiceId in choices) {
            await t.insert(
              DbTables.submissionAnswerItems,
              {
                CommonCols.id: const Uuid().v4(),
                SubmissionAnswerItemsCols.submissionAnswerId: answerId,
                SubmissionAnswerItemsCols.choiceId: choiceId as String,
                SubmissionAnswerItemsCols.answerText: null,
                SubmissionAnswerItemsCols.isCorrect: 0,
                CommonCols.cachedAt: now.toIso8601String(),
                CommonCols.syncStatus: 'pending',
              },
            );
          }
        } else if (answer['answer_text'] != null) {
          await t.insert(
            DbTables.submissionAnswerItems,
            {
              CommonCols.id: const Uuid().v4(),
              SubmissionAnswerItemsCols.submissionAnswerId: answerId,
              SubmissionAnswerItemsCols.choiceId: null,
              SubmissionAnswerItemsCols.answerText: answer['answer_text'] as String,
              SubmissionAnswerItemsCols.isCorrect: 0,
              CommonCols.cachedAt: now.toIso8601String(),
              CommonCols.syncStatus: 'pending',
            },
          );
        }
      }

      await t.update(
        DbTables.assessmentSubmissions,
        {
          CommonCols.syncStatus: 'pending',
          CommonCols.updatedAt: now.toIso8601String(),
          CommonCols.cachedAt: now.toIso8601String(),
        },
        where: '${CommonCols.id} = ?',
        whereArgs: [submissionId],
      );
    }

    if (txn != null) {
      await doSave(txn);
    } else {
      await db.transaction((innerTxn) async {
        await doSave(innerTxn);
      });
    }
  } catch (e) {
    throw CacheException('Failed to save answers locally: $e');
  }
}
