import 'package:likha/core/database/db_schema.dart';
import 'package:likha/core/database/local_database.dart';
import 'package:likha/core/errors/exceptions.dart';
import 'package:sqflite_sqlcipher/sqflite.dart';

Future<void> overrideAnswer(
  LocalDatabase localDatabase,
  String answerId,
  bool isCorrect,
  double? points, {
  Transaction? txn,
}) async {
  try {
    final now = DateTime.now();

    Future<void> doUpdate(Transaction t) async {
      final answerResults = await t.query(
        'submission_answers',
        where: 'id = ?',
        whereArgs: [answerId],
      );

      if (answerResults.isNotEmpty) {
        final submissionId = answerResults.first['submission_id'] as String;

        await t.update(
          'submission_answer_items',
          {
            'is_correct': isCorrect ? 1 : 0,
          },
          where: 'submission_answer_id = ?',
          whereArgs: [answerId],
        );

        final answerUpdates = <String, dynamic>{
          SubmissionAnswersCols.overriddenAt: now.toIso8601String(),
        };
        if (points != null) {
          answerUpdates[SubmissionAnswersCols.points] = points;
        }
        await t.update(
          'submission_answers',
          answerUpdates,
          where: 'id = ?',
          whereArgs: [answerId],
        );

        await t.update(
          'assessment_submissions',
          {
            CommonCols.syncStatus: 'pending',
            CommonCols.updatedAt: now.toIso8601String(),
          },
          where: 'id = ?',
          whereArgs: [submissionId],
        );
      }
    }

    if (txn != null) {
      await doUpdate(txn);
    } else {
      final db = await localDatabase.database;
      await db.transaction((innerTxn) async {
        await doUpdate(innerTxn);
      });
    }
  } catch (e) {
    throw CacheException('Failed to override answer locally: $e');
  }
}
