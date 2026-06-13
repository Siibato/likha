import 'package:dartz/dartz.dart';
import 'package:likha/core/errors/failures.dart';
import 'package:likha/core/network/server_reachability_service.dart';
import 'package:likha/core/utils/typedef.dart';
import 'package:likha/data/datasources/local/grading/grading_local_datasource.dart';
import 'package:likha/data/datasources/remote/grading/grading_remote_datasource.dart';
import 'package:likha/domain/grading/entities/grade_config.dart';

import '_helpers.dart' as helpers;

ResultFuture<List<GradeConfig>> getGradingConfig(
  ServerReachabilityService serverReachabilityService,
  GradingLocalDataSource localDataSource,
  GradingRemoteDataSource remoteDataSource, {
  required String classId,
}) async {
  try {
    // Fetch from server when online so the UI always reflects server state.
    if (serverReachabilityService.isServerReachable) {
      try {
        final models = await remoteDataSource.getGradingConfig(classId: classId);
        if (models.isNotEmpty) {
          try { await localDataSource.saveConfigs(models); } catch (_) {}
          return Right(models.map(helpers.configToEntity).toList());
        }
        // Server returned empty — config may be pending sync; fall through to cache.
      } catch (_) {
        // Server fetch failed — fall through to cache.
      }
    }

    final cached = await localDataSource.getConfigByClass(classId);
    if (cached.isNotEmpty) {
      return Right(cached.map(helpers.configToEntity).toList());
    }

    // Cache empty AND server wasn't tried (isServerReachable was false).
    // This happens during cold open: the health-check ping hasn't resolved yet
    // so isServerReachable is still false even though the server is online.
    // Make one fallback attempt so we don't permanently show "not configured".
    if (!serverReachabilityService.isServerReachable) {
      try {
        final models = await remoteDataSource.getGradingConfig(classId: classId);
        if (models.isNotEmpty) {
          try { await localDataSource.saveConfigs(models); } catch (_) {}
          return Right(models.map(helpers.configToEntity).toList());
        }
      } catch (_) {
        // Genuinely offline — return empty list.
      }
    }

    return const Right([]);
  } catch (e) {
    return Left(CacheFailure(e.toString()));
  }
}
