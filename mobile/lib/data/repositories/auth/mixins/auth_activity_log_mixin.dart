import 'package:dartz/dartz.dart';
import 'package:likha/core/errors/exceptions.dart';
import 'package:likha/core/errors/failures.dart';
import 'package:likha/core/utils/typedef.dart';
import 'package:likha/data/models/auth/activity_log_model.dart';
import 'package:likha/data/repositories/auth/auth_repository_base.dart';
import 'package:likha/domain/auth/entities/activity_log.dart';

mixin AuthActivityLogMixin on AuthRepositoryBase {
  @override
  ResultFuture<List<ActivityLog>> getActivityLogs({
    required String userId,
  }) async {
    try {
      try {
        final cachedLogs = await localDataSource.getCachedActivityLogs(userId);
        _syncActivityLogsInBackground(userId);
        return Right(cachedLogs);
      } on CacheException {
        if (!serverReachabilityService.isServerReachable) {
          return const Left(NetworkFailure('No internet connection and no cached data'));
        }

        final freshLogs = await remoteDataSource.getActivityLogs(userId: userId);
        await localDataSource.cacheActivityLogs(
          freshLogs as List<ActivityLogModel>,
          userId,
        );
        return Right(freshLogs);
      }
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  void _syncActivityLogsInBackground(String userId) {
    if (!serverReachabilityService.isServerReachable) return;

    remoteDataSource.getActivityLogs(userId: userId).then((logs) {
      localDataSource.cacheActivityLogs(
        logs as List<ActivityLogModel>,
        userId,
      );
    }).catchError((_) {
      // Best-effort sync — ignore failures
    });
  }
}