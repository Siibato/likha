import 'package:dartz/dartz.dart';
import 'package:likha/core/errors/exceptions.dart';
import 'package:likha/core/errors/failures.dart';
import 'package:likha/core/logging/repo_logger.dart';
import 'package:likha/core/sync/sync_queue.dart';
import 'package:likha/core/utils/typedef.dart';
import 'package:likha/domain/assignments/entities/assignment_submission.dart';
import 'package:uuid/uuid.dart';
import 'package:likha/core/network/server_reachability_service.dart';
import 'package:likha/data/datasources/local/assignments/assignment_local_datasource.dart';
import 'package:likha/data/datasources/remote/assignments/assignment_remote_datasource.dart';
import 'package:likha/services/storage_service.dart';
import '_helpers.dart' as helpers;

ResultFuture<AssignmentSubmission> createSubmission(
  ServerReachabilityService serverReachabilityService,
  AssignmentLocalDataSource localDataSource,
  AssignmentRemoteDataSource remoteDataSource,
  SyncQueue syncQueue,
  StorageService storageService, {
  required String assignmentId,
  String? textContent,
}) async {
  RepoLogger.instance.warn('[CREATE_SUBMISSION] START — assignmentId=$assignmentId isServerReachable=${serverReachabilityService.isServerReachable}');
  try {
    if (!serverReachabilityService.isServerReachable) {
      RepoLogger.instance.warn('[CREATE_SUBMISSION] OFFLINE PATH — creating locally');
      final studentId = await storageService.getUserId() ?? '';
      final localId = await localDataSource.createSubmission(
        assignmentId: assignmentId,
        studentId: studentId,
        textContent: textContent,
      );
      RepoLogger.instance.warn('[CREATE_SUBMISSION] OFFLINE SUCCESS — localId=$localId');
      // No direct syncQueue.enqueue — createSubmission already enqueues atomically

      return Right(AssignmentSubmission(
        id: localId,
        assignmentId: assignmentId,
        studentId: studentId,
        studentName: '',
        status: 'draft',
        textContent: textContent,
        score: null,
        feedback: null,
        // isLate field removed - no longer needed
        files: const [],
        submittedAt: null,
        gradedAt: null,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        needsSync: true,
        cachedAt: DateTime.now(),
      ));
    }

    final studentId = await storageService.getUserId() ?? '';
    final tempId = const Uuid().v4();
    final now = DateTime.now();
    final optimisticSubmission = AssignmentSubmission(
      id: tempId,
      assignmentId: assignmentId,
      studentId: studentId,
      studentName: '',
      status: 'draft',
      textContent: textContent,
      score: null,
      feedback: null,
      files: const [],
      submittedAt: null,
      gradedAt: null,
      createdAt: now,
      updatedAt: now,
      needsSync: true,
      cachedAt: now,
    );

    await localDataSource.cacheSubmissionDetail(
      helpers.toSubmissionModel(optimisticSubmission),
    );

    RepoLogger.instance.warn('[CREATE_SUBMISSION] ONLINE PATH — calling remote');
    try {
      final result = await remoteDataSource.createSubmission(
        assignmentId: assignmentId,
        textContent: textContent,
      );
      RepoLogger.instance.warn('[CREATE_SUBMISSION] ONLINE SUCCESS — id=${result.id}');
      await localDataSource.cacheSubmissionDetail(result);
      return Right(result);
    } on NetworkException catch (e) {
      RepoLogger.instance.warn('[CREATE_SUBMISSION] Online path network fallback — enqueueing. msg=${e.message}');
      await syncQueue.enqueue(SyncQueueEntry(
        id: const Uuid().v4(),
        entityType: SyncEntityType.assignmentSubmission,
        operation: SyncOperation.create,
        payload: {
          'id': tempId,
          'assignment_id': assignmentId,
          'student_id': studentId,
          if (textContent != null) 'text_content': textContent,
        },
        status: SyncStatus.pending,
        retryCount: 0,
        maxRetries: 3,
        createdAt: DateTime.now(),
      ));
      return Right(optimisticSubmission);
    }
  } on ServerException catch (e) {
    RepoLogger.instance.error('[CREATE_SUBMISSION] ServerException — ${e.message}');
    return Left(ServerFailure(e.message, statusCode: e.statusCode));
  } on NetworkException catch (e) {
    RepoLogger.instance.warn('[CREATE_SUBMISSION] NetworkException caught — falling back to offline. msg=${e.message}');
    // Server went down between health-check intervals — fall back to offline path
    try {
      final studentId = await storageService.getUserId() ?? '';
      final localId = await localDataSource.createSubmission(
        assignmentId: assignmentId,
        studentId: studentId,
        textContent: textContent,
      );
      RepoLogger.instance.warn('[CREATE_SUBMISSION] NetworkException fallback SUCCESS — localId=$localId');
      return Right(AssignmentSubmission(
        id: localId,
        assignmentId: assignmentId,
        studentId: studentId,
        studentName: '',
        status: 'draft',
        textContent: textContent,
        score: null,
        feedback: null,
        files: const [],
        submittedAt: null,
        gradedAt: null,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        needsSync: true,
        cachedAt: DateTime.now(),
      ));
    } catch (cacheErr) {
      RepoLogger.instance.error('[CREATE_SUBMISSION] NetworkException fallback FAILED — $cacheErr');
      return Left(CacheFailure(cacheErr.toString()));
    }
  } catch (e) {
    RepoLogger.instance.error('[CREATE_SUBMISSION] unexpected error — $e');
    return Left(ServerFailure(e.toString()));
  }
}
