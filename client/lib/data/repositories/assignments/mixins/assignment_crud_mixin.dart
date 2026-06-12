import 'package:dartz/dartz.dart';
import 'package:likha/core/errors/exceptions.dart';
import 'package:likha/core/errors/failures.dart';
import 'package:likha/core/utils/typedef.dart';
import 'package:likha/core/sync/sync_queue.dart';
import 'package:likha/domain/assignments/entities/assignment.dart';
import 'package:likha/data/models/assignments/assignment_model.dart';
import 'package:likha/data/repositories/assignments/assignment_repository_base.dart';
import 'package:uuid/uuid.dart';

mixin AssignmentCrudMixin on AssignmentRepositoryBase {
  @override
  ResultFuture<Assignment> createAssignment({
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
          },
        );
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

  @override
  ResultFuture<Assignment> updateAssignment({
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
          },
        );
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

  @override
  ResultVoid deleteAssignment({required String assignmentId}) async {
    try {
      await localDataSource.deleteAssignment(assignmentId: assignmentId);

      if (!serverReachabilityService.isServerReachable) {
        await syncQueue.enqueue(SyncQueueEntry(
          id: const Uuid().v4(),
          entityType: SyncEntityType.assignment,
          operation: SyncOperation.delete,
          payload: {'id': assignmentId},
          status: SyncStatus.pending,
          retryCount: 0,
          maxRetries: 5,
          createdAt: DateTime.now(),
        ));
        return const Right(null);
      }

      try {
        await remoteDataSource.deleteAssignment(assignmentId: assignmentId);
        return const Right(null);
      } on NetworkException {
        await syncQueue.enqueue(SyncQueueEntry(
          id: const Uuid().v4(),
          entityType: SyncEntityType.assignment,
          operation: SyncOperation.delete,
          payload: {'id': assignmentId},
          status: SyncStatus.pending,
          retryCount: 0,
          maxRetries: 5,
          createdAt: DateTime.now(),
        ));
        return const Right(null);
      }
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message, statusCode: e.statusCode));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  ResultFuture<Assignment> publishAssignment({
    required String assignmentId,
  }) async {
    try {
      await localDataSource.markAssignmentPublished(assignmentId: assignmentId);

      if (!serverReachabilityService.isServerReachable) {
        final cached = await localDataSource.getCachedAssignmentDetail(assignmentId);
        return Right(cached);
      }

      try {
        final result = await remoteDataSource.publishAssignment(
          assignmentId: assignmentId,
        );
        await localDataSource.cacheAssignments([result]);
        return Right(result);
      } on NetworkException {
        final cached = await localDataSource.getCachedAssignmentDetail(assignmentId);
        return Right(cached);
      }
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message, statusCode: e.statusCode));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  ResultFuture<Assignment> unpublishAssignment({
    required String assignmentId,
  }) async {
    try {
      await localDataSource.markAssignmentUnpublished(assignmentId: assignmentId);

      if (!serverReachabilityService.isServerReachable) {
        final cached = await localDataSource.getCachedAssignmentDetail(assignmentId);
        return Right(cached);
      }

      try {
        final result = await remoteDataSource.unpublishAssignment(
          assignmentId: assignmentId,
        );
        await localDataSource.cacheAssignments([result]);
        return Right(result);
      } on NetworkException {
        final cached = await localDataSource.getCachedAssignmentDetail(assignmentId);
        return Right(cached);
      }
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message, statusCode: e.statusCode));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  ResultVoid reorderAllAssignments({
    required String classId,
    required List<String> assignmentIds,
  }) async {
    try {
      if (!serverReachabilityService.isServerReachable) {
        for (int i = 0; i < assignmentIds.length; i++) {
          await localDataSource.updateAssignmentOrder(
            assignmentId: assignmentIds[i],
            orderIndex: i,
          );
          await syncQueue.enqueue(SyncQueueEntry(
            id: const Uuid().v4(),
            entityType: SyncEntityType.assignment,
            operation: SyncOperation.update,
            payload: {'id': assignmentIds[i], 'order_index': i},
            status: SyncStatus.pending,
            retryCount: 0,
            maxRetries: 5,
            createdAt: DateTime.now(),
          ));
        }
        return const Right(null);
      }
      for (int i = 0; i < assignmentIds.length; i++) {
        await localDataSource.updateAssignmentOrder(
          assignmentId: assignmentIds[i],
          orderIndex: i,
        );
      }
      try {
        await remoteDataSource.reorderAllAssignments(
          classId: classId,
          assignmentIds: assignmentIds,
        );
        return const Right(null);
      } on NetworkException {
        for (int i = 0; i < assignmentIds.length; i++) {
          await syncQueue.enqueue(SyncQueueEntry(
            id: const Uuid().v4(),
            entityType: SyncEntityType.assignment,
            operation: SyncOperation.update,
            payload: {'id': assignmentIds[i], 'order_index': i},
            status: SyncStatus.pending,
            retryCount: 0,
            maxRetries: 5,
            createdAt: DateTime.now(),
          ));
        }
        return const Right(null);
      }
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message, statusCode: e.statusCode));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}