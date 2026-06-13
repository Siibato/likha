import 'package:dartz/dartz.dart';
import 'package:likha/core/errors/exceptions.dart';
import 'package:likha/core/errors/failures.dart';
import 'package:likha/core/sync/sync_queue.dart';
import 'package:likha/core/utils/typedef.dart';
import 'package:likha/data/models/assignments/assignment_model.dart';
import 'package:likha/domain/assignments/entities/assignment.dart';
import 'package:uuid/uuid.dart';
import 'package:likha/core/network/server_reachability_service.dart';
import 'package:likha/data/datasources/local/assignments/assignment_local_datasource.dart';
import 'package:likha/data/datasources/remote/assignments/assignment_remote_datasource.dart';

ResultFuture<Assignment> updateAssignment(
  ServerReachabilityService serverReachabilityService,
  AssignmentLocalDataSource localDataSource,
  AssignmentRemoteDataSource remoteDataSource,
  SyncQueue syncQueue, {
  required String assignmentId,
  String? title,
  String? instructions,
  int? totalPoints,
  bool? allowsTextSubmission,
  bool? allowsFileSubmission,
  String? allowedFileTypes,
  int? maxFileSizeMb,
  String? dueAt,
}) async {
  try {
    final cached = await localDataSource.getCachedAssignmentDetail(assignmentId);
    final optimisticAssignment = cached.copyWith(
      title: title,
      instructions: instructions,
      totalPoints: totalPoints,
      allowsTextSubmission: allowsTextSubmission,
      allowsFileSubmission: allowsFileSubmission,
      allowedFileTypes: allowedFileTypes,
      maxFileSizeMb: maxFileSizeMb,
      dueAt: dueAt != null ? DateTime.parse(dueAt) : null,
      updatedAt: DateTime.now(),
      needsSync: true,
    );

    await localDataSource.cacheAssignmentDetail(
      AssignmentModel(
        id: optimisticAssignment.id,
        classId: optimisticAssignment.classId,
        title: optimisticAssignment.title,
        instructions: optimisticAssignment.instructions,
        totalPoints: optimisticAssignment.totalPoints,
        allowsTextSubmission: optimisticAssignment.allowsTextSubmission,
        allowsFileSubmission: optimisticAssignment.allowsFileSubmission,
        allowedFileTypes: optimisticAssignment.allowedFileTypes,
        maxFileSizeMb: optimisticAssignment.maxFileSizeMb,
        dueAt: optimisticAssignment.dueAt,
        isPublished: optimisticAssignment.isPublished,
        orderIndex: optimisticAssignment.orderIndex,
        submissionCount: optimisticAssignment.submissionCount,
        gradedCount: optimisticAssignment.gradedCount,
        submissionStatus: optimisticAssignment.submissionStatus,
        submissionId: optimisticAssignment.submissionId,
        score: optimisticAssignment.score,
        gradingPeriodNumber: optimisticAssignment.gradingPeriodNumber,
        component: optimisticAssignment.component,
        createdAt: optimisticAssignment.createdAt,
        updatedAt: optimisticAssignment.updatedAt,
        cachedAt: optimisticAssignment.cachedAt,
        needsSync: true,
      ),
    );

    if (!serverReachabilityService.isServerReachable) {
      await syncQueue.enqueue(SyncQueueEntry(
        id: const Uuid().v4(),
        entityType: SyncEntityType.assignment,
        operation: SyncOperation.update,
        payload: {
          'id': assignmentId,
          if (title != null) 'title': title,
          if (instructions != null) 'instructions': instructions,
          if (totalPoints != null) 'total_points': totalPoints,
          if (allowsTextSubmission != null) 'allows_text_submission': allowsTextSubmission,
          if (allowsFileSubmission != null) 'allows_file_submission': allowsFileSubmission,
          if (allowedFileTypes != null) 'allowed_file_types': allowedFileTypes,
          if (maxFileSizeMb != null) 'max_file_size_mb': maxFileSizeMb,
          if (dueAt != null) 'due_at': dueAt,
        },
        status: SyncStatus.pending,
        retryCount: 0,
        maxRetries: 5,
        createdAt: DateTime.now(),
      ));

      return Right(optimisticAssignment);
    }

    try {
      final result = await remoteDataSource.updateAssignment(
        assignmentId: assignmentId,
        data: {
          if (title != null) 'title': title,
          if (instructions != null) 'instructions': instructions,
          if (totalPoints != null) 'total_points': totalPoints,
          if (allowsTextSubmission != null) 'allows_text_submission': allowsTextSubmission,
          if (allowsFileSubmission != null) 'allows_file_submission': allowsFileSubmission,
          if (allowedFileTypes != null) 'allowed_file_types': allowedFileTypes,
          if (maxFileSizeMb != null) 'max_file_size_mb': maxFileSizeMb,
          if (dueAt != null) 'due_at': dueAt,
        });
      await localDataSource.cacheAssignments([result]);
      return Right(result);
    } on NetworkException {
      await syncQueue.enqueue(SyncQueueEntry(
        id: const Uuid().v4(),
        entityType: SyncEntityType.assignment,
        operation: SyncOperation.update,
        payload: {
          'id': assignmentId,
          if (title != null) 'title': title,
          if (instructions != null) 'instructions': instructions,
          if (totalPoints != null) 'total_points': totalPoints,
          if (allowsTextSubmission != null) 'allows_text_submission': allowsTextSubmission,
          if (allowsFileSubmission != null) 'allows_file_submission': allowsFileSubmission,
          if (allowedFileTypes != null) 'allowed_file_types': allowedFileTypes,
          if (maxFileSizeMb != null) 'max_file_size_mb': maxFileSizeMb,
          if (dueAt != null) 'due_at': dueAt,
        },
        status: SyncStatus.pending,
        retryCount: 0,
        maxRetries: 5,
        createdAt: DateTime.now(),
      ));
      return Right(optimisticAssignment);
    }
  } on ServerException catch (e) {
    return Left(ServerFailure(e.message, statusCode: e.statusCode));
  } on NetworkException catch (e) {
    return Left(NetworkFailure(e.message));
  } catch (e) {
    return Left(ServerFailure(e.toString()));
  }
}
