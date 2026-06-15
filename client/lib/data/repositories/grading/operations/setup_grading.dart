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
import 'package:likha/domain/grading/entities/grade_config.dart';

import '_helpers.dart' as helpers;

ResultFuture<MutationResult<List<GradeConfig>>> setupGrading(
  GradingLocalDataSource localDataSource,
  SyncQueue syncQueue,
  GradingRemoteDataSource remoteDataSource, {
  required String classId,
  required String gradeLevel,
  required String subjectGroup,
  required String schoolYear,
  int? semester,
}) async {
  try {
    final weights = helpers.weightPresets[subjectGroup];
    final now = DateTime.now();
    final queueEntryId = const Uuid().v4();
    final configs = <GradeConfigModel>[];

    if (weights != null) {
      final nowStr = now.toIso8601String();
      for (int q = 1; q <= 4; q++) {
        configs.add(GradeConfigModel(
          id: const Uuid().v4(),
          classId: classId,
          gradingPeriodNumber: q,
          wwWeight: weights.ww,
          ptWeight: weights.pt,
          qaWeight: weights.qa,
          createdAt: nowStr,
          updatedAt: nowStr,
        ));
      }
    }

    final db = await localDataSource.localDatabase.database;
    await db.transaction((txn) async {
      await localDataSource.saveConfigs(configs, txn: txn);
      await syncQueue.enqueue(
        SyncQueueEntry(
          id: queueEntryId,
          entityType: SyncEntityType.gradeConfig,
          operation: SyncOperation.setup,
          payload: {
            'class_id': classId,
            'grade_level': gradeLevel,
            'subject_group': subjectGroup,
            'school_year': schoolYear,
            if (semester != null) 'semester': semester,
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
      remote: () => remoteDataSource.setupGrading(
        classId: classId,
        data: {
          'class_id': classId,
          'grade_level': gradeLevel,
          'subject_group': subjectGroup,
          'school_year': schoolYear,
          if (semester != null) 'semester': semester,
        },
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

    final entities = configs.map(helpers.configToEntity).toList();
    return Right(MutationResult(entity: entities, status: SyncStatus.pending));
  } catch (e) {
    return Left(ServerFailure(e.toString()));
  }
}
