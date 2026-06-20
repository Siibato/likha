import 'package:sqflite_sqlcipher/sqflite.dart';
import 'package:uuid/uuid.dart';

import 'package:likha/core/database/db_schema.dart';
import 'package:likha/core/database/local_database.dart';
import 'package:likha/core/sync/sync_queue.dart';

Future<void> updateTransmutedGrade(
  LocalDatabase localDatabase,
  SyncQueue syncQueue,
  String classId,
  String studentId,
  int gradingPeriodNumber,
  int transmutedGrade, {
  Transaction? txn,
}) async {
  final now = DateTime.now();

  Future<void> doWrite(DatabaseExecutor executor) async {
    await executor.update(
      DbTables.periodGrades,
      {
        PeriodGradesCols.transmutedGrade: transmutedGrade,
        CommonCols.updatedAt: now.toIso8601String(),
        CommonCols.syncStatus: 'pending',
        CommonCols.cachedAt: now.toIso8601String(),
      },
      where: '${PeriodGradesCols.classId} = ? AND '
          '${PeriodGradesCols.studentId} = ? AND '
          '${PeriodGradesCols.gradingPeriodNumber} = ?',
      whereArgs: [classId, studentId, gradingPeriodNumber],
    );
  }

  if (txn != null) {
    await doWrite(txn);
  } else {
    final db = await localDatabase.database;
    await db.transaction((innerTxn) async {
      await doWrite(innerTxn);
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
      ), txn: innerTxn);
    });
  }
}
