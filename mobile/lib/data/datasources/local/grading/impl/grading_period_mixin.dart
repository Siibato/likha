import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

import 'package:likha/core/database/db_schema.dart';
import 'package:likha/core/sync/sync_queue.dart';
import 'package:likha/data/models/grading/period_grade_model.dart';
import '../grading_local_datasource_base.dart';

mixin GradingPeriodMixin on GradingLocalDataSourceBase {
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
