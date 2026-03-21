import 'package:sqflite/sqflite.dart';

import 'package:likha/core/database/db_schema.dart';
import 'package:likha/core/database/local_database.dart';
import 'package:likha/core/sync/sync_queue.dart';
import 'package:likha/data/datasources/local/grading/grading_local_datasource.dart';
import 'package:likha/data/models/grading/grade_config_model.dart';
import 'package:likha/data/models/grading/grade_item_model.dart';
import 'package:likha/data/models/grading/grade_score_model.dart';
import 'package:likha/data/models/grading/quarterly_grade_model.dart';

class GradingLocalDataSourceImpl implements GradingLocalDataSource {
  final LocalDatabase localDatabase;
  final SyncQueue syncQueue;

  GradingLocalDataSourceImpl(this.localDatabase, this.syncQueue);

  // ===== Config =====

  @override
  Future<List<GradeConfigModel>> getConfigByClass(String classId) async {
    final db = await localDatabase.database;
    final results = await db.query(
      DbTables.gradeComponentsConfig,
      where: '${GradeComponentsConfigCols.classId} = ?',
      whereArgs: [classId],
      orderBy: '${GradeComponentsConfigCols.quarter} ASC',
    );
    return results.map((row) => GradeConfigModel.fromMap(row)).toList();
  }

  @override
  Future<void> saveConfigs(List<GradeConfigModel> configs) async {
    final db = await localDatabase.database;
    final batch = db.batch();
    for (final config in configs) {
      batch.insert(
        DbTables.gradeComponentsConfig,
        config.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  // ===== Grade Items =====

  @override
  Future<List<GradeItemModel>> getItemsByClassQuarter(
    String classId,
    int quarter, {
    String? component,
  }) async {
    final db = await localDatabase.database;
    var where =
        '${GradeItemsCols.classId} = ? AND ${GradeItemsCols.quarter} = ?';
    final whereArgs = <dynamic>[classId, quarter];

    if (component != null) {
      where += ' AND ${GradeItemsCols.component} = ?';
      whereArgs.add(component);
    }

    final results = await db.query(
      DbTables.gradeItems,
      where: where,
      whereArgs: whereArgs,
      orderBy: '${GradeItemsCols.orderIndex} ASC',
    );
    return results.map((row) => GradeItemModel.fromMap(row)).toList();
  }

  @override
  Future<void> saveItems(List<GradeItemModel> items) async {
    final db = await localDatabase.database;
    final batch = db.batch();
    for (final item in items) {
      batch.insert(
        DbTables.gradeItems,
        item.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  @override
  Future<void> saveItem(GradeItemModel item) async {
    final db = await localDatabase.database;
    await db.insert(
      DbTables.gradeItems,
      item.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<void> deleteItem(String id) async {
    final db = await localDatabase.database;
    await db.delete(
      DbTables.gradeItems,
      where: '${CommonCols.id} = ?',
      whereArgs: [id],
    );
  }

  @override
  Future<void> updateItemFields(String id, Map<String, dynamic> data) async {
    final db = await localDatabase.database;
    final updates = <String, dynamic>{
      CommonCols.updatedAt: DateTime.now().toIso8601String(),
      CommonCols.cachedAt: DateTime.now().toIso8601String(),
      CommonCols.needsSync: 1,
    };
    if (data.containsKey('title')) {
      updates[GradeItemsCols.title] = data['title'];
    }
    if (data.containsKey('component')) {
      updates[GradeItemsCols.component] = data['component'];
    }
    if (data.containsKey('total_points')) {
      updates[GradeItemsCols.totalPoints] = data['total_points'];
    }
    if (data.containsKey('order_index')) {
      updates[GradeItemsCols.orderIndex] = data['order_index'];
    }
    await db.update(
      DbTables.gradeItems,
      updates,
      where: '${CommonCols.id} = ?',
      whereArgs: [id],
    );
  }

  @override
  Future<void> softDeleteItem(String id) async {
    final db = await localDatabase.database;
    await db.update(
      DbTables.gradeItems,
      {
        CommonCols.deletedAt: DateTime.now().toIso8601String(),
        CommonCols.needsSync: 1,
      },
      where: '${CommonCols.id} = ?',
      whereArgs: [id],
    );
  }

  // ===== Scores =====

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
    for (final score in scores) {
      // Check for existing score by grade_item_id + student_id
      final existing = await db.query(
        DbTables.gradeScores,
        where:
            '${GradeScoresCols.gradeItemId} = ? AND ${GradeScoresCols.studentId} = ?',
        whereArgs: [gradeItemId, score.studentId],
      );

      if (existing.isNotEmpty) {
        // Update existing score
        await db.update(
          DbTables.gradeScores,
          {
            GradeScoresCols.score: score.score,
            CommonCols.updatedAt: score.updatedAt,
            CommonCols.cachedAt: DateTime.now().toIso8601String(),
            CommonCols.needsSync: 1,
          },
          where: '${CommonCols.id} = ?',
          whereArgs: [existing.first[CommonCols.id]],
        );
      } else {
        // Insert new score with needsSync = 1
        final map = score.toMap();
        map[CommonCols.needsSync] = 1;
        await db.insert(
          DbTables.gradeScores,
          map,
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    }
  }

  @override
  Future<void> updateScoreOverride(
      String scoreId, double? overrideScore) async {
    final db = await localDatabase.database;
    await db.update(
      DbTables.gradeScores,
      {
        GradeScoresCols.overrideScore: overrideScore,
        CommonCols.updatedAt: DateTime.now().toIso8601String(),
        CommonCols.cachedAt: DateTime.now().toIso8601String(),
        CommonCols.needsSync: 1,
      },
      where: '${CommonCols.id} = ?',
      whereArgs: [scoreId],
    );
  }

  // ===== Quarterly Grades =====

  @override
  Future<List<QuarterlyGradeModel>> getQuarterlyGradesByClass(
    String classId,
    int quarter,
  ) async {
    final db = await localDatabase.database;
    final results = await db.query(
      DbTables.quarterlyGrades,
      where:
          '${QuarterlyGradesCols.classId} = ? AND ${QuarterlyGradesCols.quarter} = ?',
      whereArgs: [classId, quarter],
    );
    return results.map((row) => QuarterlyGradeModel.fromMap(row)).toList();
  }

  @override
  Future<List<QuarterlyGradeModel>> getStudentAllQuarters(
    String classId,
    String studentId,
  ) async {
    final db = await localDatabase.database;
    final results = await db.query(
      DbTables.quarterlyGrades,
      where:
          '${QuarterlyGradesCols.classId} = ? AND ${QuarterlyGradesCols.studentId} = ?',
      whereArgs: [classId, studentId],
      orderBy: '${QuarterlyGradesCols.quarter} ASC',
    );
    return results.map((row) => QuarterlyGradeModel.fromMap(row)).toList();
  }

  @override
  Future<void> saveQuarterlyGrades(List<QuarterlyGradeModel> grades) async {
    final db = await localDatabase.database;
    final batch = db.batch();
    for (final grade in grades) {
      batch.insert(
        DbTables.quarterlyGrades,
        grade.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }
}
