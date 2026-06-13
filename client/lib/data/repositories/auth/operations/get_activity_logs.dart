import 'package:dartz/dartz.dart';
import 'package:likha/core/errors/exceptions.dart';
import 'package:likha/core/errors/failures.dart';
import 'package:likha/core/network/server_reachability_service.dart';
import 'package:likha/core/utils/typedef.dart';
import 'package:likha/data/datasources/local/auth/auth_local_datasource.dart';
import 'package:likha/data/datasources/remote/auth/auth_remote_datasource.dart';
import 'package:likha/domain/auth/entities/activity_log.dart';

ResultFuture<List<ActivityLog>> getActivityLogs(
  ServerReachabilityService serverReachabilityService,
  AuthLocalDataSource localDataSource,
  AuthRemoteDataSource remoteDataSource, {
  required String userId,
}) async {
  try {
    try {
      final cachedLogs = await localDataSource.getCachedActivityLogs(userId);
      _syncActivityLogsInBackground(serverReachabilityService, localDataSource, remoteDataSource, userId);
      return Right(cachedLogs);
    } on CacheException {
      if (!serverReachabilityService.isServerReachable) {
        return const Left(NetworkFailure('No internet connection and no cached data'));
      }

      final freshLogs = await remoteDataSource.getActivityLogs(userId: userId);
      await localDataSource.cacheActivityLogs(
        freshLogs,
        userId,
      );
      return Right(freshLogs);
    }
  } on ServerException catch (e) {
    return Left(ServerFailure(e.message, statusCode: e.statusCode));
  } on NetworkException catch (e) {
    return Left(NetworkFailure(e.message));
  } catch (e) {
    return Left(ServerFailure(e.toString()));
  }
}

void _syncActivityLogsInBackground(
  ServerReachabilityService serverReachabilityService,
  AuthLocalDataSource localDataSource,
  AuthRemoteDataSource remoteDataSource,
  String userId,
) {
  if (!serverReachabilityService.isServerReachable) return;

  remoteDataSource.getActivityLogs(userId: userId).then((logs) {
    localDataSource.cacheActivityLogs(
      logs,
      userId,
    );
  }).catchError((_) {
    // Best-effort sync — ignore failures
  });
}
