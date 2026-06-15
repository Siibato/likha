import 'package:dartz/dartz.dart';
import 'package:uuid/uuid.dart';
import 'package:likha/core/database/db_schema.dart';
import 'package:likha/core/errors/exceptions.dart';
import 'package:likha/core/errors/failures.dart';
import 'package:likha/core/sync/mutation_result.dart';
import 'package:likha/core/sync/sync_queue.dart';
import 'package:likha/core/utils/remote_write.dart';
import 'package:likha/core/utils/typedef.dart';
import 'package:likha/data/datasources/local/grading/grading_local_datasource.dart';
import 'package:likha/data/datasources/remote/grading/grading_remote_datasource.dart';
import 'package:likha/data/models/grading/grade_item_model.dart';
import 'package:likha/domain/grading/entities/grade_item.dart';

import '_helpers.dart' as helpers;

ResultFuture<MutationResult<GradeItem>> createGradeItem(
  GradingLocalDataSource localDataSource,
  SyncQueue syncQueue,
  GradingRemoteDataSource remoteDataSource, {
  required String classId,
  required Map<String, dynamic> data,
}) async {
  try {
    final now = DateTime.now();
    final id = const Uuid().v4();
    final queueEntryId = const Uuid().v4();

    final model = GradeItemModel(
      id: id,
      classId: classId,
      title: data['title'] as String,
      component: data['component'] as String,
      gradingPeriodNumber: (data['grading_period_number'] as num?)?.toInt() ?? (data['quarter'] as num?)?.toInt() ?? 1,
      totalPoints: (data['total_points'] as num).toDouble(),
      sourceType: (data['source_type'] as String?) ?? 'manual',
      sourceId: data['source_id'] as String?,
      orderIndex: (data['order_index'] as num?)?.toInt() ?? 0,
      createdAt: now,
      updatedAt: now,
    );

    final db = await localDataSource.localDatabase.database;
    await db.transaction((txn) async {
      await localDataSource.saveItem(model, txn: txn);
      await syncQueue.enqueue(
        SyncQueueEntry(
          id: queueEntryId,
          entityType: SyncEntityType.gradeItem,
          operation: SyncOperation.create,
          payload: {
            'id': id,
            'class_id': classId,
            ...data,
          },
          status: SyncStatus.pending,
          retryCount: 0,
          maxRetries: 5,
          createdAt: now,
        ),
        txn: txn,
      );
    });

    fireRemoteWrite<GradeItemModel>(
      remote: () => remoteDataSource.createGradeItem(
        classId: classId,
        data: data,
        idempotencyKey: queueEntryId,
      ),
      onSuccess: (serverModel) async {
        final db = await localDataSource.localDatabase.database;

        if (serverModel.id != id) {
          await db.update(
            DbTables.gradeItems,
            {CommonCols.id: serverModel.id},
            where: '${CommonCols.id} = ?',
            whereArgs: [id],
          );
        }

        await db.update(
          DbTables.gradeItems,
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
          DbTables.gradeItems,
          {CommonCols.syncStatus: SyncStatus.failed.dbValue},
          where: '${CommonCols.id} = ?',
          whereArgs: [id],
        );
        await syncQueue.markFailed(queueEntryId, error.toString());
      },
    );

    return Right(MutationResult(entity: helpers.itemToEntity(model), status: SyncStatus.pending));
  } catch (e) {
    return Left(ServerFailure(e.toString()));
  }
}
