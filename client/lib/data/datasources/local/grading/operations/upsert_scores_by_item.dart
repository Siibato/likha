import 'package:sqflite_sqlcipher/sqflite.dart';
import 'package:uuid/uuid.dart';

import 'package:likha/core/database/db_schema.dart';
import 'package:likha/core/database/local_database.dart';
import 'package:likha/core/sync/sync_queue.dart';
import 'package:likha/data/models/grading/grade_score_model.dart';

Future<void> upsertScoresByItem(
  LocalDatabase localDatabase,
  SyncQueue syncQueue,
  String gradeItemId,
  List<GradeScoreModel> scores, {
  Transaction? txn,
}) async {
  final now = DateTime.now();

  Future<void> doWrite(DatabaseExecutor executor) async {
    for (final score in scores) {
      // Check for existing score by grade_item_id + student_id
      final existing = await executor.query(
        DbTables.gradeScores,
        where:
            '${GradeScoresCols.gradeItemId} = ? AND ${GradeScoresCols.studentId} = ?',
        whereArgs: [gradeItemId, score.studentId],
      );

      if (existing.isNotEmpty) {
        final existingRow = existing.first;
        final wasAutoPopulated = (existingRow[GradeScoresCols.isAutoPopulated] as int? ?? 0) == 1;
        final hasNoScore = existingRow[GradeScoresCols.score] == null;
        final hasOverride = existingRow[GradeScoresCols.overrideScore] != null;
        final incomingIsManual = !score.isAutoPopulated;

        // Allow update when:
        //   - teacher is editing (incomingIsManual): teacher always wins
        //   - existing row was auto-populated AND has no override: safe to refresh
        //   - existing row has no score yet: fill the blank
        // Skip when auto-populate tries to overwrite a row that has an override
        // or a row that the teacher manually edited (is_auto_populated = 0).
        if (incomingIsManual || ((wasAutoPopulated || hasNoScore) && !hasOverride)) {
          await executor.update(
            DbTables.gradeScores,
            {
              GradeScoresCols.score: score.score,
              GradeScoresCols.isAutoPopulated: score.isAutoPopulated ? 1 : 0,
              // Only touch override_score when teacher is explicitly saving —
              // auto-populate must never blank out an existing override.
              if (incomingIsManual) GradeScoresCols.overrideScore: score.overrideScore,
              CommonCols.updatedAt: score.updatedAt,
              CommonCols.cachedAt: now.toIso8601String(),
              CommonCols.syncStatus: 'pending',
            },
            where: '${CommonCols.id} = ?',
            whereArgs: [existingRow[CommonCols.id]],
          );
        }
        // else: row has a teacher override or manual edit — leave it untouched
      } else {
        // Insert new score with needsSync = 1
        final map = score.toMap();
        map[CommonCols.syncStatus] = 'pending';
        map[CommonCols.cachedAt] = now.toIso8601String();
        await executor.insert(
          DbTables.gradeScores,
          map,
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    }
  }

  if (txn != null) {
    await doWrite(txn);
  } else {
    final db = await localDatabase.database;
    await db.transaction((innerTxn) async {
      await doWrite(innerTxn);
      // Enqueue a single bulk operation with all scores
      await syncQueue.enqueue(SyncQueueEntry(
        id: const Uuid().v4(),
        entityType: SyncEntityType.gradeScore,
        operation: SyncOperation.saveScores,
        payload: {
          'grade_item_id': gradeItemId,
          'scores': scores.map((s) => s.toMap()).toList(),
        },
        status: SyncStatus.pending,
        retryCount: 0,
        maxRetries: 3,
        createdAt: now,
      ), txn: innerTxn);
    });
  }
}
