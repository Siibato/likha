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
import 'package:likha/data/models/grading/grade_config_model.dart';

ResultFuture<MutationResult<void>> updateGradingConfig(
  GradingLocalDataSource localDataSource,
  SyncQueue syncQueue,
  GradingRemoteDataSource remoteDataSource, {
  required String classId,
  required List<Map<String, dynamic>> configs,
}) async {
  try {
    final now = DateTime.now();
    final nowStr = now.toIso8601String();
    final queueEntryId = const Uuid().v4();

    final models = configs.map((c) => GradeConfigModel(
      id: c['id'] as String? ?? const Uuid().v4(),
      classId: classId,
      gradingPeriodNumber: (c['grading_period_number'] as num?)?.toInt() ?? (c['quarter'] as num).toInt(),
      wwWeight: (c['ww_weight'] as num).toDouble(),
      ptWeight: (c['pt_weight'] as num).toDouble(),
      qaWeight: (c['qa_weight'] as num).toDouble(),
      createdAt: nowStr,
      updatedAt: nowStr,
    )).toList();

    final db = await localDataSource.localDatabase.database;
    await db.transaction((txn) async {
      await localDataSource.saveConfigs(models, txn: txn);
      await syncQueue.enqueue(
        SyncQueueEntry(
          id: queueEntryId,
          entityType: SyncEntityType.gradeConfig,
          operation: SyncOperation.update,
          payload: {
            'class_id': classId,
            'configs': configs,
          },
          status: SyncStatus.pending,
          retryCount: 0,
          maxRetries: 5,
          createdAt: now,
        ),
        txn: txn,
      );
    });

    fireRemoteWrite<void>(
      remote: () => remoteDataSource.updateGradingConfig(
        classId: classId,
        configs: configs,
        idempotencyKey: queueEntryId,
      ),
      onSuccess: (_) async {
        final db = await localDataSource.localDatabase.database;
        await db.update(
          DbTables.gradeRecord,
          {CommonCols.syncStatus: SyncStatus.synced.dbValue},
          where: '${GradeRecordCols.classId} = ?',
          whereArgs: [classId],
        );
        await syncQueue.markSucceeded(queueEntryId);
      },
      onError: (error) async {
        if (error is NetworkException) {
          return;
        }

        final db = await localDataSource.localDatabase.database;
        await db.update(
          DbTables.gradeRecord,
          {CommonCols.syncStatus: SyncStatus.failed.dbValue},
          where: '${GradeRecordCols.classId} = ?',
          whereArgs: [classId],
        );
        await syncQueue.markFailed(queueEntryId, error.toString());
      },
    );

    return const Right(MutationResult(entity: null, status: SyncStatus.pending));
  } catch (e) {
    return Left(ServerFailure(e.toString()));
  }
}
