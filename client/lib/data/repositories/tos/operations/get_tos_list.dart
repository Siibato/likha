import 'package:dartz/dartz.dart';
import 'package:likha/core/errors/failures.dart';
import 'package:likha/core/network/server_reachability_service.dart';
import 'package:likha/core/utils/typedef.dart';
import 'package:likha/data/datasources/local/tos/tos_local_datasource.dart';
import 'package:likha/data/datasources/remote/tos/tos_remote_datasource.dart';
import 'package:likha/domain/tos/entities/tos_entity.dart';

ResultFuture<List<TableOfSpecifications>> getTosList(
  ServerReachabilityService serverReachabilityService,
  TosLocalDataSource localDataSource,
  TosRemoteDataSource remoteDataSource, {
  required String classId,
}) async {
  try {
    final cached = await localDataSource.getTosByClass(classId);

    if (cached.isNotEmpty) {
      // Has local data — return it immediately and background-refresh.
      if (serverReachabilityService.isServerReachable) {
        _backgroundFetchTosList(serverReachabilityService, localDataSource, remoteDataSource, classId);
      }
      return Right(cached);
    }

    if (serverReachabilityService.isServerReachable) {
      final models = await remoteDataSource.getTosByClass(classId: classId);
      await localDataSource.cacheTosList(models);
      return Right(models);
    }

    return const Right([]);
  } catch (e) {
    return Left(CacheFailure(e.toString()));
  }
}

void _backgroundFetchTosList(
  ServerReachabilityService serverReachabilityService,
  TosLocalDataSource localDataSource,
  TosRemoteDataSource remoteDataSource,
  String classId,
) async {
  try {
    final models = await remoteDataSource.getTosByClass(classId: classId);
    await localDataSource.cacheTosList(models);
  } catch (_) {
    // Non-fatal: background refresh failure
  }
}
