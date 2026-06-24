import 'package:likha/core/database/db_schema.dart';
import 'package:likha/core/database/local_database.dart';
import 'package:likha/core/errors/exceptions.dart';
import 'package:sqflite_sqlcipher/sqflite.dart';

Future<void> gradeEssay(
  LocalDatabase localDatabase,
  String answerId,
  double points, {
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
          'submission_answers',
          {
            SubmissionAnswersCols.points: points,
            SubmissionAnswersCols.overriddenAt: now.toIso8601String(),
          },
          where: 'id = ?',
          whereArgs: [answerId],
        );

        // Recalculate submission earned_points from all answer points
        final sumResult = await t.rawQuery(
          'SELECT COALESCE(SUM(points), 0.0) as total FROM submission_answers WHERE submission_id = ?',
          [submissionId],
        );
        final newEarned = (sumResult.first['total'] as num?)?.toDouble() ?? 0.0;

        await t.update(
          'assessment_submissions',
          {
            AssessmentSubmissionsCols.earnedPoints: newEarned,
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
    throw CacheException('Failed to grade essay locally: $e');
  }
}
