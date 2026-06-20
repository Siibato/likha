import 'package:dartz/dartz.dart';
import 'package:likha/core/errors/exceptions.dart';
import 'package:likha/core/errors/failures.dart';
import 'package:likha/core/events/data_event_bus.dart';
import 'package:likha/core/utils/remote_fetch.dart';
import 'package:likha/core/utils/typedef.dart';
import 'package:likha/data/datasources/local/grading/grading_local_datasource.dart';
import 'package:likha/data/datasources/remote/grading/grading_remote_datasource.dart';
import 'package:likha/domain/grading/entities/grade_config.dart';

import '_helpers.dart' as helpers;

ResultFuture<List<GradeConfig>> getGradingConfig(
  GradingLocalDataSource localDataSource,
  GradingRemoteDataSource remoteDataSource,
  DataEventBus dataEventBus, {
  required String classId,
}) async {
  try {
    try {
      final cached = await localDataSource.getConfigByClass(classId);

      // Treat empty list as cache miss
      if (cached.isEmpty) {
        throw CacheException('No cached grading config found');
      }

      fireRemoteFetch(
        dedupKey: 'grading/config/$classId/bg',
        remote: () => remoteDataSource.getGradingConfig(classId: classId),
        onSuccess: (fresh) async {
          if (fresh.isNotEmpty) {
            try {
              final current = await localDataSource.getConfigByClass(classId);
              if (current.length != fresh.length) {
                try { await localDataSource.saveConfigs(fresh); } catch (_) {}
                dataEventBus.notifyGradesChanged(classId);
                return;
              }
              final currentById = {for (final c in current) c.id: c};
              for (final f in fresh) {
                final c = currentById[f.id];
                if (c == null ||
                    c.wwWeight != f.wwWeight ||
                    c.ptWeight != f.ptWeight ||
                    c.qaWeight != f.qaWeight ||
                    c.termNumber != f.termNumber) {
                  try { await localDataSource.saveConfigs(fresh); } catch (_) {}
                  dataEventBus.notifyGradesChanged(classId);
                  return;
                }
              }
            } catch (_) {
              try { await localDataSource.saveConfigs(fresh); } catch (_) {}
              dataEventBus.notifyGradesChanged(classId);
            }
          }
        },
      );

      return Right(cached.map(helpers.configToEntity).toList());
    } on CacheException {
      final fresh = await remoteFetch(
        dedupKey: 'grading/config/$classId',
        remote: () => remoteDataSource.getGradingConfig(classId: classId),
      );
      try { await localDataSource.saveConfigs(fresh); } catch (_) {}
      return Right(fresh.map(helpers.configToEntity).toList());
    }
  } on ServerException catch (e) {
    return Left(ServerFailure(e.message, statusCode: e.statusCode));
  } on NetworkException catch (e) {
    return Left(NetworkFailure(e.message));
  } on CacheException catch (e) {
    return Left(CacheFailure(e.message));
  } catch (e) {
    return Left(ServerFailure(e.toString()));
  }
}
