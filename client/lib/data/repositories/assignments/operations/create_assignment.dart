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

ResultFuture<Assignment> createAssignment(
  ServerReachabilityService serverReachabilityService,
  AssignmentLocalDataSource localDataSource,
  AssignmentRemoteDataSource remoteDataSource,
  SyncQueue syncQueue, {
  required String classId,
  required String title,
  required String instructions,
  required int totalPoints,
  required bool allowsTextSubmission,
  required bool allowsFileSubmission,
  String? allowedFileTypes,
  int? maxFileSizeMb,
  required String dueAt,
  bool isPublished = true,
  int? gradingPeriodNumber,
  String? component,
  bool? noSubmissionRequired,
}) async {
  try {
    if (!serverReachabilityService.isServerReachable) {
      final assignmentId = const Uuid().v4();

      await syncQueue.enqueue(SyncQueueEntry(
        id: const Uuid().v4(),
        entityType: SyncEntityType.assignment,
        operation: SyncOperation.create,
        payload: {
          'id': assignmentId,
          'class_id': classId,
          'title': title,
          'instructions': instructions,
          'total_points': totalPoints,
          'allows_text_submission': allowsTextSubmission,
          'allows_file_submission': allowsFileSubmission,
          if (allowedFileTypes != null) 'allowed_file_types': allowedFileTypes,
          if (maxFileSizeMb != null) 'max_file_size_mb': maxFileSizeMb,
          'due_at': dueAt,
          'is_published': isPublished,
          if (gradingPeriodNumber != null) 'grading_period_number': gradingPeriodNumber,
          if (component != null) 'component': component,
          if (noSubmissionRequired != null) 'no_submission_required': noSubmissionRequired,
        },
        status: SyncStatus.pending,
        retryCount: 0,
        maxRetries: 5,
        createdAt: DateTime.now(),
      ));

      final optimisticAssignment = Assignment(
        id: assignmentId,
        classId: classId,
        title: title,
        instructions: instructions,
        totalPoints: totalPoints,
        allowsTextSubmission: allowsTextSubmission,
        allowsFileSubmission: allowsFileSubmission,
        allowedFileTypes: allowedFileTypes,
        maxFileSizeMb: maxFileSizeMb,
        dueAt: DateTime.parse(dueAt),
        isPublished: isPublished,
        orderIndex: 0,
        submissionCount: 0,
        gradedCount: 0,
        gradingPeriodNumber: gradingPeriodNumber,
        component: component,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      try {
        final currentCached =
            await localDataSource.getCachedAssignments(classId);
        final optimisticModel = AssignmentModel(
          id: assignmentId,
          classId: classId,
          title: title,
          instructions: instructions,
          totalPoints: totalPoints,
          allowsTextSubmission: allowsTextSubmission,
          allowsFileSubmission: allowsFileSubmission,
          allowedFileTypes: allowedFileTypes,
          maxFileSizeMb: maxFileSizeMb,
          dueAt: DateTime.parse(dueAt),
          isPublished: isPublished,
          orderIndex: 0,
          submissionCount: 0,
          gradedCount: 0,
          gradingPeriodNumber: gradingPeriodNumber,
          component: component,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        await localDataSource
            .cacheAssignments([optimisticModel, ...currentCached]);
      } catch (_) {}

      return Right(optimisticAssignment);
    }

    final localId = const Uuid().v4();
    final localNow = DateTime.now();
    final optimisticModel = AssignmentModel(
      id: localId,
      classId: classId,
      title: title,
      instructions: instructions,
      totalPoints: totalPoints,
      allowsTextSubmission: allowsTextSubmission,
      allowsFileSubmission: allowsFileSubmission,
      allowedFileTypes: allowedFileTypes,
      maxFileSizeMb: maxFileSizeMb,
      dueAt: DateTime.parse(dueAt),
      isPublished: isPublished,
      orderIndex: 0,
      submissionCount: 0,
      gradedCount: 0,
      gradingPeriodNumber: gradingPeriodNumber,
      component: component,
      createdAt: localNow,
      updatedAt: localNow,
      needsSync: true,
    );

    await localDataSource.cacheAssignments([optimisticModel]);

    try {
      final result = await remoteDataSource.createAssignment(
        classId: classId,
        data: {
          'title': title,
          'instructions': instructions,
          'total_points': totalPoints,
          'allows_text_submission': allowsTextSubmission,
          'allows_file_submission': allowsFileSubmission,
          if (allowedFileTypes != null) 'allowed_file_types': allowedFileTypes,
          if (maxFileSizeMb != null) 'max_file_size_mb': maxFileSizeMb,
          'due_at': dueAt,
          'is_published': isPublished,
          if (gradingPeriodNumber != null) 'grading_period_number': gradingPeriodNumber,
          if (component != null) 'component': component,
          if (noSubmissionRequired != null) 'no_submission_required': noSubmissionRequired,
        });
      if (result.id != localId) {
        await localDataSource.deleteAssignment(assignmentId: localId);
      }
      await localDataSource.cacheAssignments([result]);
      return Right(result);
    } on NetworkException {
      await syncQueue.enqueue(SyncQueueEntry(
        id: const Uuid().v4(),
        entityType: SyncEntityType.assignment,
        operation: SyncOperation.create,
        payload: {
          'id': localId,
          'class_id': classId,
          'title': title,
          'instructions': instructions,
          'total_points': totalPoints,
          'allows_text_submission': allowsTextSubmission,
          'allows_file_submission': allowsFileSubmission,
          if (allowedFileTypes != null) 'allowed_file_types': allowedFileTypes,
          if (maxFileSizeMb != null) 'max_file_size_mb': maxFileSizeMb,
          'due_at': dueAt,
          'is_published': isPublished,
          if (gradingPeriodNumber != null) 'grading_period_number': gradingPeriodNumber,
          if (component != null) 'component': component,
          if (noSubmissionRequired != null) 'no_submission_required': noSubmissionRequired,
        },
        status: SyncStatus.pending,
        retryCount: 0,
        maxRetries: 5,
        createdAt: DateTime.now(),
      ));
      return Right(optimisticModel);
    }
  } on ServerException catch (e) {
    return Left(ServerFailure(e.message, statusCode: e.statusCode));
  } on NetworkException catch (e) {
    return Left(NetworkFailure(e.message));
  } catch (e) {
    return Left(ServerFailure(e.toString()));
  }
}
