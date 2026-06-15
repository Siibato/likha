import 'package:dartz/dartz.dart';
import 'package:likha/core/database/db_schema.dart';
import 'package:likha/core/errors/exceptions.dart';
import 'package:likha/core/errors/failures.dart';
import 'package:likha/core/sync/mutation_result.dart';
import 'package:likha/core/sync/sync_queue.dart';
import 'package:likha/core/utils/remote_write.dart';
import 'package:likha/core/utils/typedef.dart';
import 'package:likha/data/datasources/local/classes/class_local_datasource.dart';
import 'package:likha/data/datasources/remote/classes/class_remote_datasource.dart';
import 'package:likha/data/models/classes/class_model.dart';
import 'package:uuid/uuid.dart';

ResultFuture<MutationResult<ClassModel>> createClass(
  ClassLocalDataSource localDataSource,
  SyncQueue syncQueue,
  ClassRemoteDataSource remoteDataSource, {
  required String title,
  String? description,
  String? teacherId,
  String? teacherUsername,
  String? teacherFullName,
  bool isAdvisory = false,
}) async {
  try {
    final classId = const Uuid().v4();
    final queueEntryId = const Uuid().v4();
    final now = DateTime.now();

    final optimisticModel = ClassModel(
      id: classId,
      title: title,
      description: description,
      teacherId: teacherId ?? '',
      teacherUsername: teacherUsername ?? '',
      teacherFullName: teacherFullName ?? '',
      isArchived: false,
      isAdvisory: isAdvisory,
      studentCount: 0,
      gradingPeriodType: 'quarter',
      createdAt: now,
      updatedAt: now,
      syncStatus: SyncStatus.pending,
    );

    final db = await localDataSource.localDatabase.database;
    await db.transaction((txn) async {
      await localDataSource.insertClass(optimisticModel, txn: txn);
      await syncQueue.enqueue(
        SyncQueueEntry(
          id: queueEntryId,
          entityType: SyncEntityType.classEntity,
          operation: SyncOperation.create,
          payload: optimisticModel.toPayload(),
          status: SyncStatus.pending,
          retryCount: 0,
          maxRetries: 5,
          createdAt: now,
        ),
        txn: txn,
      );
    });

    fireRemoteWrite<ClassModel>(
      remote: () => remoteDataSource.createClass(
        title: title,
        description: description,
        teacherId: teacherId,
        isAdvisory: isAdvisory,
        idempotencyKey: queueEntryId,
      ),
      onSuccess: (serverModel) async {
        final db = await localDataSource.localDatabase.database;

        if (serverModel.id != classId) {
          await db.update(
            DbTables.classes,
            {CommonCols.id: serverModel.id},
            where: '${CommonCols.id} = ?',
            whereArgs: [classId],
          );
        }

        await db.update(
          DbTables.classes,
          {CommonCols.syncStatus: SyncStatus.synced.dbValue},
          where: '${CommonCols.id} = ?',
          whereArgs: [serverModel.id],
        );
        await syncQueue.markSucceeded(queueEntryId);
      },
      onError: (error) async {
        if (error is NetworkException) {
          return;
        }

        final db = await localDataSource.localDatabase.database;
        await db.update(
          DbTables.classes,
          {CommonCols.syncStatus: SyncStatus.failed.dbValue},
          where: '${CommonCols.id} = ?',
          whereArgs: [classId],
        );
        await syncQueue.markFailed(queueEntryId, error.toString());
      },
    );

    return Right(MutationResult(entity: optimisticModel, status: SyncStatus.pending));
  } catch (e) {
    return Left(ServerFailure(e.toString()));
  }
}
