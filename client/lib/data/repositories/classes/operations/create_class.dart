import 'package:dartz/dartz.dart';
import 'package:likha/core/errors/exceptions.dart';
import 'package:likha/core/errors/failures.dart';
import 'package:likha/core/network/server_reachability_service.dart';
import 'package:likha/core/sync/sync_queue.dart';
import 'package:likha/core/utils/typedef.dart';
import 'package:likha/data/datasources/local/classes/class_local_datasource.dart';
import 'package:likha/data/datasources/remote/classes/class_remote_datasource.dart';
import 'package:likha/data/models/classes/class_model.dart';
import 'package:likha/domain/classes/entities/class_entity.dart';
import 'package:likha/services/storage_service.dart';
import 'package:uuid/uuid.dart';

ResultFuture<ClassEntity> createClass(
  ServerReachabilityService serverReachabilityService,
  ClassLocalDataSource localDataSource,
  ClassRemoteDataSource remoteDataSource,
  SyncQueue syncQueue,
  StorageService storageService, {
  required String title,
  String? description,
  String? teacherId,
  String? teacherUsername,
  String? teacherFullName,
  bool isAdvisory = false,
}) async {
  try {
    // Client-side duplicate check before creating
    try {
      final allCached = await localDataSource.getCachedClasses();
      final normalizedTitle = title.trim().toLowerCase();
      if (teacherId != null) {
        final hasDuplicate = allCached.any(
          (c) => c.teacherId == teacherId && c.title.toLowerCase() == normalizedTitle,
        );
        if (hasDuplicate) {
          return Left(ServerFailure(
            'A class named "${title.trim()}" already exists for this teacher',
          ));
        }
      }
    } catch (_) {
      // Cache check failed, proceed with normal flow (server will validate)
    }

    if (!serverReachabilityService.isServerReachable) {
      final localId = const Uuid().v4();

      await syncQueue.enqueue(SyncQueueEntry(
        id: const Uuid().v4(),
        entityType: SyncEntityType.classEntity,
        operation: SyncOperation.create,
        payload: {
          'id': localId,
          'title': title,
          'description': description,
          if (teacherId != null) 'teacher_id': teacherId,
          'is_advisory': isAdvisory,
        },
        status: SyncStatus.pending,
        retryCount: 0,
        maxRetries: 5,
        createdAt: DateTime.now(),
      ));

      final now = DateTime.now();
      final optimisticModel = ClassModel(
        id: localId,
        title: title,
        description: description,
        teacherId: teacherId ?? '',
        teacherUsername: teacherUsername ?? '',
        teacherFullName: teacherFullName ?? '',
        isArchived: false,
        isAdvisory: isAdvisory,
        studentCount: 0,
        createdAt: now,
        updatedAt: now,
      );

      try {
        final currentUserId = await storageService.getUserId();
        final cached = await localDataSource.getCachedClasses(teacherId: currentUserId);
        await localDataSource.cacheClasses([optimisticModel, ...cached]);
      } catch (_) {
        await localDataSource.cacheClasses([optimisticModel]);
      }

      return Right(optimisticModel);
    }

    final result = await remoteDataSource.createClass(
      title: title,
      description: description,
      teacherId: teacherId,
      isAdvisory: isAdvisory,
    );

    // Cache the result immediately so it appears in the list
    try {
      final cached = await localDataSource.getCachedClasses();
      await localDataSource.cacheClasses([result, ...cached]);
    } catch (_) {
      await localDataSource.cacheClasses([result]);
    }

    return Right(result);
  } on ServerException catch (e) {
    return Left(ServerFailure(e.message, statusCode: e.statusCode));
  } on NetworkException catch (e) {
    return Left(NetworkFailure(e.message));
  } catch (e) {
    return Left(ServerFailure(e.toString()));
  }
}
