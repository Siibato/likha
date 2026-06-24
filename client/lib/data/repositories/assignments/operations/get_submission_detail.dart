import 'package:dartz/dartz.dart';
import 'package:likha/core/errors/exceptions.dart';
import 'package:likha/core/errors/failures.dart';
import 'package:likha/core/utils/remote_fetch.dart';
import 'package:likha/core/utils/typedef.dart';
import 'package:likha/domain/assignments/entities/assignment_submission.dart';
import 'package:likha/data/datasources/local/assignments/assignment_local_datasource.dart';
import 'package:likha/data/datasources/remote/assignments/assignment_remote_datasource.dart';
import '_helpers.dart' as helpers;

ResultFuture<AssignmentSubmission> getSubmissionDetail(
  AssignmentLocalDataSource localDataSource,
  AssignmentRemoteDataSource remoteDataSource, {
  required String submissionId,
}) async {
  try {
    try {
      final cached = await localDataSource.getCachedSubmission(submissionId);
      if (cached != null) {
        fireRemoteFetch(
          dedupKey: 'assignments/submission/$submissionId/bg',
          remote: () => remoteDataSource.getSubmissionDetail(submissionId: submissionId),
          onSuccess: (fresh) async {
            final current = await localDataSource.getCachedSubmission(submissionId);
            if (helpers.submissionDataHasChanged(current, fresh)) {
              await localDataSource.cacheSubmissionDetail(fresh);
            }
          },
        );
        return Right(cached);
      }
    } on CacheException {
      // Cache miss — fall through to server fetch
    }

    final fresh = await remoteFetch(
      dedupKey: 'assignments/submission/$submissionId',
      remote: () => remoteDataSource.getSubmissionDetail(submissionId: submissionId),
    );
    await localDataSource.cacheSubmissionDetail(fresh);

    // Auto-repair: load from cache to restore file.localPath from disk if files exist
    try {
      final cached = await localDataSource.getCachedSubmission(submissionId);
      if (cached != null) {
        return Right(cached);
      }
    } catch (_) {
      // Auto-repair failed, return server result as fallback
    }
    return Right(fresh);
  } on ServerException catch (e) {
    return Left(ServerFailure(e.message, statusCode: e.statusCode));
  } on NetworkException catch (e) {
    return Left(NetworkFailure(e.message));
  } catch (e) {
    return Left(ServerFailure(e.toString()));
  }
}
