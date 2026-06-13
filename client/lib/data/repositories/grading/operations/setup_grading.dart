import 'package:dartz/dartz.dart';
import 'package:uuid/uuid.dart';
import 'package:likha/core/errors/failures.dart';
import 'package:likha/core/network/server_reachability_service.dart';
import 'package:likha/core/sync/sync_queue.dart';
import 'package:likha/core/utils/typedef.dart';
import 'package:likha/data/datasources/local/grading/grading_local_datasource.dart';
import 'package:likha/data/datasources/remote/grading/grading_remote_datasource.dart';
import 'package:likha/data/models/grading/grade_config_model.dart';

import '_helpers.dart' as helpers;

ResultVoid setupGrading(
  ServerReachabilityService serverReachabilityService,
  GradingLocalDataSource localDataSource,
  GradingRemoteDataSource remoteDataSource,
  SyncQueue syncQueue, {
  required String classId,
  required String gradeLevel,
  required String subjectGroup,
  required String schoolYear,
  int? semester,
}) async {
  try {
    // Save locally first (optimistic) — mirror server behaviour: Q1-Q4
    final weights = helpers.weightPresets[subjectGroup];
    if (weights != null) {
      final now = DateTime.now().toIso8601String();
      final configs = [
        for (int q = 1; q <= 4; q++)
          GradeConfigModel(
            id: const Uuid().v4(),
            classId: classId,
            gradingPeriodNumber: q,
            wwWeight: weights.ww,
            ptWeight: weights.pt,
            qaWeight: weights.qa,
            createdAt: now,
            updatedAt: now,
          ),
      ];
      await localDataSource.saveConfigs(configs);
    }

    // If online, attempt direct remote call first.
    // Only fall back to sync queue when the direct call fails so we avoid
    // sending a duplicate "setup" operation that would hit the server's
    // UNIQUE(class_id, quarter) constraint and be permanently marked failed.
    bool remoteSucceeded = false;
    if (serverReachabilityService.isServerReachable) {
      try {
        await remoteDataSource.setupGrading(
          classId: classId,
          data: {
            'grade_level': gradeLevel,
            'subject_group': subjectGroup,
            'school_year': schoolYear,
            if (semester != null) 'semester': semester,
          },
        );
        remoteSucceeded = true;
        // Next getGradingConfig call will fetch server-assigned IDs
        // automatically (server-first pattern).
      } catch (_) {
        // Direct call failed — sync queue will handle it below
      }
    }

    if (!remoteSucceeded) {
      await syncQueue.enqueue(SyncQueueEntry(
        id: const Uuid().v4(),
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
        maxRetries: 3,
        createdAt: DateTime.now(),
      ));
    }

    return const Right(null);
  } catch (e) {
    return Left(CacheFailure(e.toString()));
  }
}
