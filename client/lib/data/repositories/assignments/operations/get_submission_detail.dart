import 'package:dartz/dartz.dart';
import 'package:likha/core/errors/exceptions.dart';
import 'package:likha/core/errors/failures.dart';
import 'package:likha/core/utils/typedef.dart';
import 'package:likha/domain/assignments/entities/assignment_submission.dart';
import 'package:likha/core/events/data_event_bus.dart';
import 'package:likha/core/network/server_reachability_service.dart';
import 'package:likha/data/datasources/local/assignments/assignment_local_datasource.dart';
import 'package:likha/data/datasources/remote/assignments/assignment_remote_datasource.dart';
import '_helpers.dart' as helpers;

ResultFuture<AssignmentSubmission> getSubmissionDetail(
  ServerReachabilityService serverReachabilityService,
  AssignmentLocalDataSource localDataSource,
  AssignmentRemoteDataSource remoteDataSource,
  DataEventBus dataEventBus, {
  required String submissionId,
}) async {
  try {
    // Cache-primary strategy: always return cached data if available (mirrors getMaterialDetail pattern)
    // This ensures file.localPath (written by cacheFileBytes during download) is preserved
    try {
      final cached = await localDataSource.getCachedSubmission(submissionId);
      if (cached != null) {
        // Background refresh if server is reachable (non-blocking)
        if (serverReachabilityService.isServerReachable) {
          helpers.backgroundRefreshSubmission(localDataSource, remoteDataSource, dataEventBus, submissionId);
        }
        return Right(cached);
      }
    } on CacheException {
      // Cache miss — fall through to server fetch
    }

    // Cache miss: fetch from server
    try {
      final result = await remoteDataSource.getSubmissionDetail(
          submissionId: submissionId);
      // Await cache write to ensure DB is ready for subsequent reads
      await localDataSource.cacheSubmissionDetail(result);

      // Auto-repair: load from cache to restore file.localPath from disk if files exist
      // This ensures files downloaded in previous sessions show as cached on initial load
      try {
        final cached = await localDataSource.getCachedSubmission(submissionId);
        if (cached != null) {
          return Right(cached);
        }
      } catch (_) {
        // Auto-repair failed, return server result as fallback
      }
      return Right(result);
    } on NetworkException {
      // Server unreachable and cache is empty
      rethrow;
    }
  } on ServerException catch (e) {
    return Left(ServerFailure(e.message, statusCode: e.statusCode));
  } on NetworkException catch (e) {
    return Left(NetworkFailure(e.message));
  } catch (e) {
    return Left(ServerFailure(e.toString()));
  }
}
