import 'package:dartz/dartz.dart';
import 'package:likha/core/errors/exceptions.dart';
import 'package:likha/core/errors/failures.dart';
import 'package:likha/core/logging/repo_logger.dart';
import 'package:likha/core/sync/sync_queue.dart';
import 'package:likha/core/utils/typedef.dart';
import 'package:likha/data/models/assignments/assignment_submission_model.dart';
import 'package:likha/domain/assignments/entities/assignment_submission.dart';
import 'package:uuid/uuid.dart';
import 'package:likha/core/network/server_reachability_service.dart';
import 'package:likha/data/datasources/local/assignments/assignment_local_datasource.dart';
import 'package:likha/data/datasources/remote/assignments/assignment_remote_datasource.dart';
import '_helpers.dart' as helpers;

ResultFuture<AssignmentSubmission> submitAssignment(
  ServerReachabilityService serverReachabilityService,
  AssignmentLocalDataSource localDataSource,
  AssignmentRemoteDataSource remoteDataSource,
  SyncQueue syncQueue, {
  required String submissionId,
}) async {
  RepoLogger.instance.warn('[SUBMIT_ASSIGNMENT] START — submissionId=$submissionId isServerReachable=${serverReachabilityService.isServerReachable}');
  try {
    if (!serverReachabilityService.isServerReachable) {
      RepoLogger.instance.warn('[SUBMIT_ASSIGNMENT] OFFLINE PATH — submitting locally');
      final cached = await localDataSource.getCachedSubmission(submissionId);
      RepoLogger.instance.warn('[SUBMIT_ASSIGNMENT] cached submission — id=${cached?.id} status=${cached?.status} assignmentId=${cached?.assignmentId}');
      final assignmentId = cached?.assignmentId ?? '';
      await localDataSource.submitAssignment(
        submissionId: submissionId,
        assignmentId: assignmentId,
      );
      // No direct syncQueue.enqueue — submitAssignment already enqueues atomically

      // Read the freshly-updated cached row for a complete response
      final updated = await localDataSource.getCachedSubmission(submissionId);
      if (updated != null) return Right(updated);
      
      // Fallback: create a submitted submission with preserved text content
      return Right(AssignmentSubmission(
        id: submissionId,
        assignmentId: cached?.assignmentId ?? assignmentId,
        studentId: cached?.studentId ?? '',
        studentName: cached?.studentName ?? '',
        status: 'submitted',
        // isLate field removed - no longer needed
        files: cached?.files ?? const [],
        textContent: cached?.textContent, // Preserve the text content!
        score: cached?.score,
        feedback: cached?.feedback,
        submittedAt: DateTime.now(),
        gradedAt: cached?.gradedAt,
        createdAt: cached?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
        needsSync: true,
        cachedAt: DateTime.now(),
      ));
    }

    final cached = await localDataSource.getCachedSubmission(submissionId);
    final assignmentId = cached?.assignmentId ?? '';
    final optimisticSubmission = AssignmentSubmission(
      id: submissionId,
      assignmentId: assignmentId,
      studentId: cached?.studentId ?? '',
      studentName: cached?.studentName ?? '',
      status: 'submitted',
      files: cached?.files ?? const [],
      textContent: cached?.textContent,
      score: cached?.score,
      feedback: cached?.feedback,
      submittedAt: DateTime.now(),
      gradedAt: cached?.gradedAt,
      createdAt: cached?.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
      needsSync: true,
      cachedAt: DateTime.now(),
    );
    await localDataSource.cacheSubmissionDetail(
      helpers.toSubmissionModel(optimisticSubmission),
    );

    RepoLogger.instance.warn('[SUBMIT_ASSIGNMENT] ONLINE PATH — calling remote');
    try {
      final result = await remoteDataSource.submitAssignment(
          submissionId: submissionId);
      RepoLogger.instance.warn('[SUBMIT_ASSIGNMENT] ONLINE SUCCESS — id=${result.id} status=${result.status}');

      try {
        await localDataSource.cacheSubmissions(
          result.assignmentId,
          [SubmissionListItemModel(
            id: result.id,
            studentId: result.studentId,
            studentName: result.studentName,
            studentUsername: '',
            status: result.status,
            submittedAt: result.submittedAt,
            score: result.score,
          )],
        );
      } catch (_) {}

      await localDataSource.cacheSubmissionDetail(result);
      return Right(result);
    } on NetworkException catch (e) {
      RepoLogger.instance.warn('[SUBMIT_ASSIGNMENT] Online path network fallback — enqueueing. msg=${e.message}');
      await syncQueue.enqueue(SyncQueueEntry(
        id: const Uuid().v4(),
        entityType: SyncEntityType.assignmentSubmission,
        operation: SyncOperation.submit,
        payload: {
          'submission_id': submissionId,
          'assignment_id': assignmentId,
          if (optimisticSubmission.textContent != null && optimisticSubmission.textContent!.isNotEmpty)
            'text_content': optimisticSubmission.textContent,
        },
        status: SyncStatus.pending,
        retryCount: 0,
        maxRetries: 3,
        createdAt: DateTime.now(),
      ));
      return Right(optimisticSubmission);
    }
  } on ServerException catch (e) {
    RepoLogger.instance.error('[SUBMIT_ASSIGNMENT] ServerException — ${e.message}');
    return Left(ServerFailure(e.message, statusCode: e.statusCode));
  } on NetworkException catch (e) {
    RepoLogger.instance.warn('[SUBMIT_ASSIGNMENT] NetworkException caught — falling back to offline. msg=${e.message}');
    // Server went down between health-check intervals — fall back to offline path
    try {
      final cached = await localDataSource.getCachedSubmission(submissionId);
      RepoLogger.instance.warn('[SUBMIT_ASSIGNMENT] NetworkException fallback — cached=${cached?.id} status=${cached?.status}');
      final assignmentId = cached?.assignmentId ?? '';
      await localDataSource.submitAssignment(
        submissionId: submissionId,
        assignmentId: assignmentId,
      );
      final updated = await localDataSource.getCachedSubmission(submissionId);
      RepoLogger.instance.warn('[SUBMIT_ASSIGNMENT] NetworkException fallback SUCCESS — updated=${updated?.id} status=${updated?.status}');
      if (updated != null) return Right(updated);
      return Right(AssignmentSubmission(
        id: submissionId,
        assignmentId: cached?.assignmentId ?? assignmentId,
        studentId: cached?.studentId ?? '',
        studentName: cached?.studentName ?? '',
        status: 'submitted',
        files: cached?.files ?? const [],
        textContent: cached?.textContent,
        score: cached?.score,
        feedback: cached?.feedback,
        submittedAt: DateTime.now(),
        gradedAt: cached?.gradedAt,
        createdAt: cached?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
        needsSync: true,
        cachedAt: DateTime.now(),
      ));
    } catch (e) {
      RepoLogger.instance.error('[SUBMIT_ASSIGNMENT] NetworkException fallback failed — ${e.toString()}');
      return Left(CacheFailure(e.toString()));
    }
  } catch (e) {
    RepoLogger.instance.error('[SUBMIT_ASSIGNMENT] unexpected error — ${e.toString()}');
    return Left(ServerFailure(e.toString()));
  }
}
