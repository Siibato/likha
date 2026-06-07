import 'dart:convert';
import 'package:likha/core/database/db_schema.dart';
import 'package:likha/core/database/local_database.dart';
import 'package:likha/core/errors/exceptions.dart';
import 'package:likha/core/sync/sync_queue.dart';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

Future<void> saveAnswersLocallyOp(
  LocalDatabase localDatabase,
  SyncQueue syncQueue,
  String submissionId,
  String answersJson,
) async {
  try {
    final db = await localDatabase.database;
    final now = DateTime.now();
    final answers = jsonDecode(answersJson) as List<dynamic>;

    await db.transaction((txn) async {
      await txn.delete(DbTables.submissionAnswers, where: '${SubmissionAnswersCols.submissionId} = ?', whereArgs: [submissionId]);

      for (final answerData in answers) {
        final answer = answerData as Map<String, dynamic>;
        final answerId = answer['id'] as String? ?? const Uuid().v4();
        await txn.insert(
          DbTables.submissionAnswers,
          {
            CommonCols.id: answerId,
            SubmissionAnswersCols.submissionId: submissionId,
            SubmissionAnswersCols.questionId: answer['question_id'] as String,
            SubmissionAnswersCols.points: 0,
            CommonCols.cachedAt: now.toIso8601String(),
            CommonCols.needsSync: 1,
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );

        if (answer['selected_choices'] != null) {
          final choices = answer['selected_choices'] as List<dynamic>;
          for (final choiceId in choices) {
            await txn.insert(
              DbTables.submissionAnswerItems,
              {
                CommonCols.id: const Uuid().v4(),
                SubmissionAnswerItemsCols.submissionAnswerId: answerId,
                SubmissionAnswerItemsCols.choiceId: choiceId as String,
                SubmissionAnswerItemsCols.answerText: null,
                SubmissionAnswerItemsCols.isCorrect: 0,
                CommonCols.cachedAt: now.toIso8601String(),
                CommonCols.needsSync: 1,
              },
            );
          }
        } else if (answer['answer_text'] != null) {
          await txn.insert(
            DbTables.submissionAnswerItems,
            {
              CommonCols.id: const Uuid().v4(),
              SubmissionAnswerItemsCols.submissionAnswerId: answerId,
              SubmissionAnswerItemsCols.choiceId: null,
              SubmissionAnswerItemsCols.answerText: answer['answer_text'] as String,
              SubmissionAnswerItemsCols.isCorrect: 0,
              CommonCols.cachedAt: now.toIso8601String(),
              CommonCols.needsSync: 1,
            },
          );
        }
      }

      await txn.update(
        DbTables.assessmentSubmissions,
        {
          CommonCols.needsSync: 1,
          CommonCols.updatedAt: now.toIso8601String(),
          CommonCols.cachedAt: now.toIso8601String(),
        },
        where: '${CommonCols.id} = ?',
        whereArgs: [submissionId],
      );

      await syncQueue.enqueue(SyncQueueEntry(
        id: const Uuid().v4(),
        entityType: SyncEntityType.assessmentSubmission,
        operation: SyncOperation.saveAnswers,
        payload: {'submission_id': submissionId, 'answers': answers},
        status: SyncStatus.pending,
        retryCount: 0,
        maxRetries: 3,
        createdAt: now,
      ), txn: txn);
    });
  } catch (e) {
    throw CacheException('Failed to save answers locally: $e');
  }
}
