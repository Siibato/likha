import 'package:dartz/dartz.dart';
import 'package:likha/core/errors/exceptions.dart';
import 'package:likha/core/errors/failures.dart';
import 'package:likha/core/sync/sync_queue.dart';
import 'package:likha/core/utils/typedef.dart';
import 'package:likha/domain/assignments/entities/assignment_submission.dart';
import 'package:uuid/uuid.dart';
import 'package:likha/core/network/server_reachability_service.dart';
import 'package:likha/data/datasources/local/assignments/assignment_local_datasource.dart';
import 'package:likha/data/datasources/remote/assignments/assignment_remote_datasource.dart';
import '_helpers.dart' as helpers;

ResultFuture<AssignmentSubmission> returnSubmission(
  ServerReachabilityService serverReachabilityService,
  AssignmentLocalDataSource localDataSource,
  AssignmentRemoteDataSource remoteDataSource,
  SyncQueue syncQueue, {
  required String submissionId,
}) async {
  try {
    if (!serverReachabilityService.isServerReachable) {
      await localDataSource.returnSubmission(
        submissionId: submissionId,
      );
      final cached = await localDataSource.getCachedSubmission(submissionId);
      if (cached != null) return Right(cached);
      return Right(AssignmentSubmission(
        id: submissionId,
        assignmentId: '',
        studentId: '',
        studentName: '',
        status: 'returned',
        // isLate field removed - no longer needed
        files: const [],
        textContent: null,
        score: null,
        feedback: null,
        submittedAt: DateTime.now(),
        gradedAt: null,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        needsSync: true,
        cachedAt: DateTime.now(),
      ));
    }

    final cached = await localDataSource.getCachedSubmission(submissionId);
    final optimisticSubmission = cached != null
        ? AssignmentSubmission(
            id: cached.id,
            assignmentId: cached.assignmentId,
            studentId: cached.studentId,
            studentName: cached.studentName,
            status: 'returned',
            textContent: cached.textContent,
            submittedAt: cached.submittedAt,
            score: cached.score,
            feedback: cached.feedback,
            gradedAt: cached.gradedAt,
            gradedBy: cached.gradedBy,
            files: cached.files,
            createdAt: cached.createdAt,
            updatedAt: DateTime.now(),
            cachedAt: DateTime.now(),
            needsSync: true,
          )
        : AssignmentSubmission(
            id: submissionId,
            assignmentId: '',
            studentId: '',
            studentName: '',
            status: 'returned',
            files: const [],
            textContent: null,
            score: null,
            feedback: null,
            submittedAt: DateTime.now(),
            gradedAt: null,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
            needsSync: true,
            cachedAt: DateTime.now(),
          );

    await localDataSource.cacheSubmissionDetail(
      helpers.toSubmissionModel(optimisticSubmission),
    );

    try {
      final result = await remoteDataSource.returnSubmission(
          submissionId: submissionId);
      await localDataSource.cacheSubmissionDetail(result);
      return Right(result);
    } on NetworkException {
      await syncQueue.enqueue(SyncQueueEntry(
        id: const Uuid().v4(),
        entityType: SyncEntityType.assignmentSubmission,
        operation: SyncOperation.update,
        payload: {'id': submissionId, 'action': 'return'},
        status: SyncStatus.pending,
        retryCount: 0,
        maxRetries: 3,
        createdAt: DateTime.now(),
      ));
      return Right(optimisticSubmission);
    }
  } on ServerException catch (e) {
    return Left(ServerFailure(e.message, statusCode: e.statusCode));
  } on NetworkException catch (e) {
    return Left(NetworkFailure(e.message));
  } catch (e) {
    return Left(ServerFailure(e.toString()));
  }
}
