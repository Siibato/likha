import 'package:dartz/dartz.dart';
import 'package:likha/core/errors/exceptions.dart';
import 'package:likha/core/errors/failures.dart';
import 'package:likha/core/utils/typedef.dart';
import 'package:likha/data/models/assignments/assignment_submission_model.dart';
import 'package:likha/domain/assignments/entities/assignment_submission.dart';
import 'package:likha/core/network/server_reachability_service.dart';
import 'package:likha/data/datasources/local/assignments/assignment_local_datasource.dart';
import 'package:likha/data/datasources/remote/assignments/assignment_remote_datasource.dart';

ResultFuture<List<SubmissionListItem>> getSubmissions(
  ServerReachabilityService serverReachabilityService,
  AssignmentLocalDataSource localDataSource,
  AssignmentRemoteDataSource remoteDataSource, {
  required String assignmentId,
}) async {
  try {
    // Offline guard: if server is unreachable, always return from local DB
    // This ensures the teacher sees synced submissions when offline, and an empty list
    // (not an error) when submissions have never been synced for this assignment
    if (!serverReachabilityService.isServerReachable) {
      final cached =
          await localDataSource.getCachedSubmissions(assignmentId);
      return Right(cached);
    }

    try {
      final cached =
          await localDataSource.getCachedSubmissions(assignmentId);
      // Only return cache if it has data; empty cache is treated as a miss
      if (cached.isNotEmpty) {
        return Right(cached);
      }
    } on CacheException {
      // Not in local DB — fall through to remote fetch
    }

    // Cache miss or empty cache — fetch from server if reachable
    try {
      final result = await remoteDataSource.getSubmissions(
          assignmentId: assignmentId);
      await localDataSource.cacheSubmissions(
          assignmentId, result.cast<SubmissionListItemModel>());

      // Sort by submittedAt ASC (drafts last) for consistent ordering with cache queries
      final sorted = [...result]..sort((a, b) {
        if (a.submittedAt == null && b.submittedAt == null) return 0;
        if (a.submittedAt == null) return 1;
        if (b.submittedAt == null) return -1;
        return a.submittedAt!.compareTo(b.submittedAt!);
      });

      return Right(sorted);
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message, statusCode: e.statusCode));
    }
  } catch (e) {
    return Left(ServerFailure(e.toString()));
  }
}
