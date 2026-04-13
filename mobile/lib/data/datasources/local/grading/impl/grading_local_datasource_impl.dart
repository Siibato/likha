import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

import 'package:likha/core/database/db_schema.dart';
import 'package:likha/core/database/local_database.dart';
import 'package:likha/core/sync/sync_queue.dart';
import 'package:likha/data/datasources/local/grading/grading_local_datasource.dart';
import 'package:likha/data/models/grading/grade_config_model.dart';
import 'package:likha/data/models/grading/grade_item_model.dart';
import 'package:likha/data/models/grading/grade_score_model.dart';
import 'package:likha/data/models/grading/period_grade_model.dart';

class GradingLocalDataSourceImpl implements GradingLocalDataSource {
  final LocalDatabase localDatabase;
  final SyncQueue syncQueue;

  GradingLocalDataSourceImpl(this.localDatabase, this.syncQueue);

  // ===== Config =====

  @override
  Future<List<GradeConfigModel>> getConfigByClass(String classId) async {
    final db = await localDatabase.database;
    final results = await db.query(
      DbTables.gradeRecord,
      where: '${GradeRecordCols.classId} = ?',
      whereArgs: [classId],
      orderBy: '${GradeRecordCols.gradingPeriodNumber} ASC',
    );
    return results.map((row) => GradeConfigModel.fromMap(row)).toList();
  }

  @override
  Future<void> saveConfigs(List<GradeConfigModel> configs) async {
    final db = await localDatabase.database;
    final batch = db.batch();
    for (final config in configs) {
      batch.insert(
        DbTables.gradeRecord,
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
    int gradingPeriodNumber, {
    String? component,
  }) async {
    final db = await localDatabase.database;
    var where =
        '${GradeItemsCols.classId} = ? AND ${GradeItemsCols.gradingPeriodNumber} = ?';
    final whereArgs = <dynamic>[classId, gradingPeriodNumber];

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
    final now = DateTime.now();
    final updates = <String, dynamic>{
      CommonCols.updatedAt: now.toIso8601String(),
      CommonCols.cachedAt: now.toIso8601String(),
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
    await db.transaction((txn) async {
      await txn.update(
        DbTables.gradeItems,
        updates,
        where: '${CommonCols.id} = ?',
        whereArgs: [id],
      );
      await syncQueue.enqueue(SyncQueueEntry(
        id: const Uuid().v4(),
        entityType: SyncEntityType.gradeItem,
        operation: SyncOperation.update,
        payload: {'id': id, ...data},
        status: SyncStatus.pending,
        retryCount: 0,
        maxRetries: 3,
        createdAt: now,
      ), txn: txn);
    });
  }

  @override
  Future<GradeItemModel?> getItemBySourceId(String sourceId) async {
    final db = await localDatabase.database;
    final results = await db.query(
      DbTables.gradeItems,
      where: '${GradeItemsCols.sourceId} = ? AND ${CommonCols.deletedAt} IS NULL',
      whereArgs: [sourceId],
      limit: 1,
    );
    if (results.isEmpty) return null;
    return GradeItemModel.fromMap(results.first);
  }

  @override
  Future<void> softDeleteItem(String id) async {
    final db = await localDatabase.database;
    final now = DateTime.now();
    await db.transaction((txn) async {
      await txn.update(
        DbTables.gradeItems,
        {
          CommonCols.deletedAt: now.toIso8601String(),
          CommonCols.needsSync: 1,
          CommonCols.cachedAt: now.toIso8601String(),
        },
        where: '${CommonCols.id} = ?',
        whereArgs: [id],
      );
      await syncQueue.enqueue(SyncQueueEntry(
        id: const Uuid().v4(),
        entityType: SyncEntityType.gradeItem,
        operation: SyncOperation.delete,
        payload: {'id': id},
        status: SyncStatus.pending,
        retryCount: 0,
        maxRetries: 3,
        createdAt: now,
      ), txn: txn);
    });
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

  // ===== Period Grades =====

  @override
  Future<List<PeriodGradeModel>> getPeriodGradesByClass(
    String classId,
    int gradingPeriodNumber,
  ) async {
    final db = await localDatabase.database;
    final results = await db.query(
      DbTables.periodGrades,
      where:
          '${PeriodGradesCols.classId} = ? AND ${PeriodGradesCols.gradingPeriodNumber} = ?',
      whereArgs: [classId, gradingPeriodNumber],
    );
    return results.map((row) => PeriodGradeModel.fromMap(row)).toList();
  }

  @override
  Future<List<PeriodGradeModel>> getStudentAllPeriods(
    String classId,
    String studentId,
  ) async {
    final db = await localDatabase.database;
    final results = await db.query(
      DbTables.periodGrades,
      where:
          '${PeriodGradesCols.classId} = ? AND ${PeriodGradesCols.studentId} = ?',
      whereArgs: [classId, studentId],
      orderBy: '${PeriodGradesCols.gradingPeriodNumber} ASC',
    );
    return results.map((row) => PeriodGradeModel.fromMap(row)).toList();
  }

  @override
  Future<void> savePeriodGrades(List<PeriodGradeModel> grades) async {
    final db = await localDatabase.database;
    final batch = db.batch();
    for (final grade in grades) {
      batch.insert(
        DbTables.periodGrades,
        grade.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  @override
  Future<void> updateTransmutedGrade(
    String classId,
    String studentId,
    int gradingPeriodNumber,
    int transmutedGrade,
  ) async {
    final db = await localDatabase.database;
    final now = DateTime.now();
    await db.transaction((txn) async {
      await txn.update(
        DbTables.periodGrades,
        {
          PeriodGradesCols.transmutedGrade: transmutedGrade,
          CommonCols.updatedAt: now.toIso8601String(),
          CommonCols.needsSync: 1,
          CommonCols.cachedAt: now.toIso8601String(),
        },
        where: '${PeriodGradesCols.classId} = ? AND '
            '${PeriodGradesCols.studentId} = ? AND '
            '${PeriodGradesCols.gradingPeriodNumber} = ?',
        whereArgs: [classId, studentId, gradingPeriodNumber],
      );
      await syncQueue.enqueue(SyncQueueEntry(
        id: const Uuid().v4(),
        entityType: SyncEntityType.gradeScore,
        operation: SyncOperation.update,
        payload: {
          'class_id': classId,
          'student_id': studentId,
          'grading_period_number': gradingPeriodNumber,
          'transmuted_grade': transmutedGrade,
        },
        status: SyncStatus.pending,
        retryCount: 0,
        maxRetries: 3,
        createdAt: now,
      ), txn: txn);
    });
  }
}
