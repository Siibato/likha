import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

import 'package:likha/core/database/db_schema.dart';
import 'package:likha/core/sync/sync_queue.dart';
import 'package:likha/data/models/grading/grade_score_model.dart';
import '../grading_local_datasource_base.dart';

mixin GradingScoreMixin on GradingLocalDataSourceBase {
  @override
  Future<List<GradeScoreModel>> getScoresByItem(String gradeItemId) async {
    final db = await localDatabase.database;
    final results = await db.query(
      DbTables.gradeScores,
      where: '${GradeScoresCols.gradeItemId} = ?',
      whereArgs: [gradeItemId],
    );
    return results.map((row) => GradeScoreModel.fromMap(row)).toList();
  }

  @override
  Future<void> saveScores(List<GradeScoreModel> scores) async {
    final db = await localDatabase.database;
    final batch = db.batch();
    for (final score in scores) {
      batch.insert(
        DbTables.gradeScores,
        score.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  @override
  Future<void> upsertScoresByItem(
    String gradeItemId,
    List<GradeScoreModel> scores,
  ) async {
    final db = await localDatabase.database;
    final now = DateTime.now();
    await db.transaction((txn) async {
      for (final score in scores) {
        // Check for existing score by grade_item_id + student_id
        final existing = await txn.query(
          DbTables.gradeScores,
          where:
              '${GradeScoresCols.gradeItemId} = ? AND ${GradeScoresCols.studentId} = ?',
          whereArgs: [gradeItemId, score.studentId],
        );

        if (existing.isNotEmpty) {
          // Update existing score
          await txn.update(
            DbTables.gradeScores,
            {
              GradeScoresCols.score: score.score,
              CommonCols.updatedAt: score.updatedAt,
              CommonCols.cachedAt: now.toIso8601String(),
              CommonCols.needsSync: 1,
            },
            where: '${CommonCols.id} = ?',
            whereArgs: [existing.first[CommonCols.id]],
          );
        } else {
          // Insert new score with needsSync = 1
          final map = score.toMap();
          map[CommonCols.needsSync] = 1;
          map[CommonCols.cachedAt] = now.toIso8601String();
          await txn.insert(
            DbTables.gradeScores,
            map,
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
      }
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
      ), txn: txn);
    });
  }

  @override
  Future<void> updateScoreOverride(
      String scoreId, double? overrideScore) async {
    final db = await localDatabase.database;
    final now = DateTime.now();
    await db.transaction((txn) async {
      await txn.update(
        DbTables.gradeScores,
        {
          GradeScoresCols.overrideScore: overrideScore,
          CommonCols.updatedAt: now.toIso8601String(),
          CommonCols.cachedAt: now.toIso8601String(),
          CommonCols.needsSync: 1,
        },
        where: '${CommonCols.id} = ?',
        whereArgs: [scoreId],
      );
      await syncQueue.enqueue(SyncQueueEntry(
        id: const Uuid().v4(),
        entityType: SyncEntityType.gradeScore,
        operation: SyncOperation.setOverride,
        payload: {'id': scoreId, 'override_score': overrideScore},
        status: SyncStatus.pending,
        retryCount: 0,
        maxRetries: 3,
        createdAt: now,
      ), txn: txn);
    });
  }
}
