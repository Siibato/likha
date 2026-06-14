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

ResultFuture<AssignmentSubmission> gradeSubmission(
  ServerReachabilityService serverReachabilityService,
  AssignmentLocalDataSource localDataSource,
  AssignmentRemoteDataSource remoteDataSource,
  SyncQueue syncQueue, {
  required String submissionId,
  required int score,
  String? feedback,
}) async {
  try {
    if (!serverReachabilityService.isServerReachable) {
      await localDataSource.gradeSubmission(
        submissionId: submissionId,
        score: score,
        feedback: feedback,
      );
      // Read back the now-updated cached row for response
      final cached = await localDataSource.getCachedSubmission(submissionId);
      if (cached != null) return Right(cached);
      // Fallback (shouldn't happen — submission was just graded from UI which loaded it)
      return Right(AssignmentSubmission(
        id: submissionId,
        assignmentId: '',
        studentId: '',
        studentName: '',
        status: 'graded',
        // isLate field removed - no longer needed
        score: score,
        feedback: feedback,
        files: const [],
        textContent: null,
        submittedAt: DateTime.now(),
        gradedAt: DateTime.now(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        syncStatus: SyncStatus.pending,
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
            status: 'graded',
            textContent: cached.textContent,
            submittedAt: cached.submittedAt,
            score: score,
            feedback: feedback,
            gradedAt: DateTime.now(),
            gradedBy: cached.gradedBy,
            files: cached.files,
            createdAt: cached.createdAt,
            updatedAt: DateTime.now(),
            cachedAt: DateTime.now(),
            syncStatus: SyncStatus.pending,
          )
        : AssignmentSubmission(
            id: submissionId,
            assignmentId: '',
            studentId: '',
            studentName: '',
            status: 'graded',
            score: score,
            feedback: feedback,
            files: const [],
            textContent: null,
            submittedAt: DateTime.now(),
            gradedAt: DateTime.now(),
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
            syncStatus: SyncStatus.pending,
            cachedAt: DateTime.now(),
          );

    await localDataSource.cacheSubmissionDetail(
      helpers.toSubmissionModel(optimisticSubmission),
    );

    try {
      final result = await remoteDataSource.gradeSubmission(
        submissionId: submissionId,
        data: {
          'score': score,
          if (feedback != null) 'feedback': feedback,
        });
      await localDataSource.cacheSubmissionDetail(result);
      return Right(result);
    } on NetworkException {
      await syncQueue.enqueue(SyncQueueEntry(
        id: const Uuid().v4(),
        entityType: SyncEntityType.assignmentSubmission,
        operation: SyncOperation.grade,
        payload: {
          'id': submissionId,
          'score': score,
          if (feedback != null) 'feedback': feedback,
        },
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
