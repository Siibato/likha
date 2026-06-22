import 'package:dartz/dartz.dart';
import 'package:uuid/uuid.dart';
import 'package:likha/core/errors/failures.dart';
import 'package:likha/core/sync/mutation_result.dart';
import 'package:likha/core/sync/sync_queue.dart';
import 'package:likha/core/utils/typedef.dart';
import 'package:likha/data/datasources/local/grading/grading_local_datasource.dart';
import 'package:likha/data/models/grading/grade_config_model.dart';
import 'package:likha/domain/grading/entities/grade_config.dart';

import '_helpers.dart' as helpers;

ResultFuture<MutationResult<List<GradeConfig>>> setupGrading(
  GradingLocalDataSource localDataSource,
  SyncQueue syncQueue, {
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
          termNumber: q,
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

    final entities = configs.map(helpers.configToEntity).toList();
    return Right(MutationResult(entity: entities, status: SyncStatus.pending));
  } catch (e) {
    return Left(ServerFailure(e.toString()));
  }
}
