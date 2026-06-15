import 'package:dartz/dartz.dart';
import 'package:likha/core/database/db_schema.dart';
import 'package:likha/core/errors/exceptions.dart';
import 'package:likha/core/errors/failures.dart';
import 'package:likha/core/sync/sync_queue.dart';
import 'package:likha/core/utils/remote_write.dart';
import 'package:likha/core/utils/typedef.dart';
import 'package:likha/data/datasources/local/classes/class_local_datasource.dart';
import 'package:likha/data/datasources/remote/classes/class_remote_datasource.dart';
import 'package:uuid/uuid.dart';

ResultVoid removeStudent(
  ClassLocalDataSource localDataSource,
  SyncQueue syncQueue,
  ClassRemoteDataSource remoteDataSource, {
  required String classId,
  required String studentId,
}) async {
  try {
    final queueEntryId = const Uuid().v4();
    final now = DateTime.now();

    final db = await localDataSource.localDatabase.database;
    await db.transaction((txn) async {
      await localDataSource.removeStudentLocally(
        classId: classId,
        studentId: studentId,
        txn: txn,
      );
      await syncQueue.enqueue(
        SyncQueueEntry(
          id: queueEntryId,
          entityType: SyncEntityType.classEntity,
          operation: SyncOperation.removeEnrollment,
          payload: {'class_id': classId, 'student_id': studentId},
          status: SyncStatus.pending,
          retryCount: 0,
          maxRetries: 5,
          createdAt: now,
        ),
        txn: txn,
      );
    });

    fireRemoteWrite<void>(
      remote: () => remoteDataSource.removeStudent(
        classId: classId,
        studentId: studentId,
        idempotencyKey: queueEntryId,
      ),
      onSuccess: (_) async {
        final db = await localDataSource.localDatabase.database;
        await db.update(
          DbTables.classParticipants,
          {CommonCols.syncStatus: SyncStatus.synced.dbValue},
          where: '${ClassParticipantsCols.classId} = ? AND ${ClassParticipantsCols.userId} = ?',
          whereArgs: [classId, studentId],
        );
        await syncQueue.markSucceeded(queueEntryId);
      },
      onError: (error) async {
        if (error is NetworkException) {
          return;
        }

        final db = await localDataSource.localDatabase.database;
        await db.update(
          DbTables.classParticipants,
          {CommonCols.syncStatus: SyncStatus.failed.dbValue},
          where: '${ClassParticipantsCols.classId} = ? AND ${ClassParticipantsCols.userId} = ?',
          whereArgs: [classId, studentId],
        );
        await syncQueue.markFailed(queueEntryId, error.toString());
      },
    );

    return const Right(null);
  } catch (e) {
    return Left(ServerFailure(e.toString()));
  }
}
