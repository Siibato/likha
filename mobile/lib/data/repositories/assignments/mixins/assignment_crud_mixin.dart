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
    required String submissionType,
    String? allowedFileTypes,
    int? maxFileSizeMb,
    required String dueAt,
  }) async {
    try {
      if (!serverReachabilityService.isServerReachable) {
        final assignmentId = const Uuid().v4();

        await syncQueue.enqueue(SyncQueueEntry(
          id: const Uuid().v4(),
          entityType: SyncEntityType.assignment,
          operation: SyncOperation.create,
          payload: {
            'class_id': classId,
            'title': title,
            'instructions': instructions,
            'total_points': totalPoints,
            'submission_type': submissionType,
            if (allowedFileTypes != null) 'allowed_file_types': allowedFileTypes,
            if (maxFileSizeMb != null) 'max_file_size_mb': maxFileSizeMb,
            'due_at': dueAt,
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
          submissionType: submissionType,
          allowedFileTypes: allowedFileTypes,
          maxFileSizeMb: maxFileSizeMb,
          dueAt: DateTime.parse(dueAt),
          isPublished: false,
          orderIndex: 0,
          submissionCount: 0,
          gradedCount: 0,
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
            submissionType: submissionType,
            allowedFileTypes: allowedFileTypes,
            maxFileSizeMb: maxFileSizeMb,
            dueAt: DateTime.parse(dueAt),
            isPublished: false,
            orderIndex: 0,
            submissionCount: 0,
            gradedCount: 0,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );
          await localDataSource
              .cacheAssignments([optimisticModel, ...currentCached]);
        } catch (_) {}

        return Right(optimisticAssignment);
      }

      final result = await remoteDataSource.createAssignment(
        classId: classId,
        data: {
          'title': title,
          'instructions': instructions,
          'total_points': totalPoints,
          'submission_type': submissionType,
          if (allowedFileTypes != null) 'allowed_file_types': allowedFileTypes,
          if (maxFileSizeMb != null) 'max_file_size_mb': maxFileSizeMb,
          'due_at': dueAt,
        },
      );
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
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
    String? submissionType,
    String? allowedFileTypes,
    int? maxFileSizeMb,
    String? dueAt,
  }) async {
    try {
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
            if (submissionType != null) 'submission_type': submissionType,
            if (allowedFileTypes != null) 'allowed_file_types': allowedFileTypes,
            if (maxFileSizeMb != null) 'max_file_size_mb': maxFileSizeMb,
            if (dueAt != null) 'due_at': dueAt,
          },
          status: SyncStatus.pending,
          retryCount: 0,
          maxRetries: 5,
          createdAt: DateTime.now(),
        ));

        return Right(Assignment(
          id: assignmentId,
          classId: '',
          title: title ?? '',
          instructions: instructions ?? '',
          totalPoints: totalPoints ?? 0,
          submissionType: submissionType ?? '',
          allowedFileTypes: allowedFileTypes,
          maxFileSizeMb: maxFileSizeMb,
          dueAt: dueAt != null ? DateTime.parse(dueAt) : DateTime.now(),
          isPublished: false,
          orderIndex: 0,
          submissionCount: 0,
          gradedCount: 0,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ));
      }

      final result = await remoteDataSource.updateAssignment(
        assignmentId: assignmentId,
        data: {
          if (title != null) 'title': title,
          if (instructions != null) 'instructions': instructions,
          if (totalPoints != null) 'total_points': totalPoints,
          if (submissionType != null) 'submission_type': submissionType,
          if (allowedFileTypes != null) 'allowed_file_types': allowedFileTypes,
          if (maxFileSizeMb != null) 'max_file_size_mb': maxFileSizeMb,
          if (dueAt != null) 'due_at': dueAt,
        },
      );
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  ResultVoid deleteAssignment({required String assignmentId}) async {
    try {
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

      await remoteDataSource.deleteAssignment(assignmentId: assignmentId);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
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
      if (!serverReachabilityService.isServerReachable) {
        await syncQueue.enqueue(SyncQueueEntry(
          id: const Uuid().v4(),
          entityType: SyncEntityType.assignment,
          operation: SyncOperation.publish,
          payload: {'id': assignmentId},
          status: SyncStatus.pending,
          retryCount: 0,
          maxRetries: 5,
          createdAt: DateTime.now(),
        ));

        // Persist published state to local DB immediately
        await localDataSource.markAssignmentPublishedLocally(assignmentId: assignmentId);

        return Right(Assignment(
          id: assignmentId,
          classId: '',
          title: '',
          instructions: '',
          totalPoints: 0,
          submissionType: '',
          allowedFileTypes: null,
          maxFileSizeMb: null,
          dueAt: DateTime.now(),
          isPublished: true,
          orderIndex: 0,
          submissionCount: 0,
          gradedCount: 0,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ));
      }

      final result = await remoteDataSource.publishAssignment(
        assignmentId: assignmentId,
      );
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
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
      await remoteDataSource.reorderAllAssignments(
        classId: classId,
        assignmentIds: assignmentIds,
      );
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}