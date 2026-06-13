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
import 'package:uuid/uuid.dart';

ResultFuture<ClassEntity> updateClass(
  ServerReachabilityService serverReachabilityService,
  ClassLocalDataSource localDataSource,
  ClassRemoteDataSource remoteDataSource,
  SyncQueue syncQueue, {
  required String classId,
  String? title,
  String? description,
  String? teacherId,
  bool? isAdvisory,
}) async {
  try {
    if (!serverReachabilityService.isServerReachable) {
      await syncQueue.enqueue(SyncQueueEntry(
        id: const Uuid().v4(),
        entityType: SyncEntityType.classEntity,
        operation: SyncOperation.update,
        payload: {
          'id': classId,
          if (title != null) 'title': title,
          if (description != null) 'description': description,
          if (teacherId != null) 'teacher_id': teacherId,
          if (isAdvisory != null) 'is_advisory': isAdvisory,
        },
        status: SyncStatus.pending,
        retryCount: 0,
        maxRetries: 5,
        createdAt: DateTime.now(),
      ));

      try {
        final current = await localDataSource
            .getCachedClasses()
            .then((classes) => classes.firstWhere(
                  (c) => c.id == classId,
                  orElse: () => throw Exception('Class not found'),
                ));

        // Update local cache with optimistic changes
        try {
          final cachedClasses = await localDataSource.getCachedClasses();
          final updatedCache = cachedClasses.map((c) {
            if (c.id == classId) {
              return ClassModel(
                id: current.id,
                title: title ?? current.title,
                description: description ?? current.description,
                teacherId: teacherId ?? current.teacherId,
                teacherUsername: current.teacherUsername,
                teacherFullName: current.teacherFullName,
                isArchived: current.isArchived,
                isAdvisory: isAdvisory ?? current.isAdvisory,
                studentCount: current.studentCount,
                createdAt: current.createdAt,
                updatedAt: DateTime.now(),
              );
            }
            return c;
          }).toList();
          await localDataSource.cacheClasses(updatedCache);
        } catch (e) {
          // Cache failure is not critical
        }

        return Right(ClassEntity(
          id: current.id,
          title: title ?? current.title,
          description: description ?? current.description,
          teacherId: teacherId ?? current.teacherId,
          teacherUsername: current.teacherUsername,
          teacherFullName: current.teacherFullName,
          isArchived: current.isArchived,
          isAdvisory: isAdvisory ?? current.isAdvisory,
          studentCount: current.studentCount,
          createdAt: current.createdAt,
          updatedAt: DateTime.now(),
        ));
      } catch (e) {
        return const Left(CacheFailure('Class not found in cache'));
      }
    }

    // Optimistic: write to local cache before remote call
    try {
      final cachedClasses = await localDataSource.getCachedClasses();
      final optimisticCache = cachedClasses.map((c) {
        if (c.id == classId) {
          return ClassModel(
            id: c.id,
            title: title ?? c.title,
            description: description ?? c.description,
            teacherId: teacherId ?? c.teacherId,
            teacherUsername: c.teacherUsername,
            teacherFullName: c.teacherFullName,
            isArchived: c.isArchived,
            isAdvisory: isAdvisory ?? c.isAdvisory,
            studentCount: c.studentCount,
            createdAt: c.createdAt,
            updatedAt: DateTime.now(),
          );
        }
        return c;
      }).toList();
      await localDataSource.cacheClasses(optimisticCache);
    } catch (_) {}

    final result = await remoteDataSource.updateClass(
      classId: classId,
      title: title,
      description: description,
      teacherId: teacherId,
      isAdvisory: isAdvisory,
    );

    // Overwrite local cache with server-returned result
    try {
      final cachedClasses = await localDataSource.getCachedClasses();
      final updatedCache = cachedClasses.map((c) => c.id == classId ? result : c).toList();
      await localDataSource.cacheClasses(updatedCache);
    } catch (_) {}

    return Right(result);
  } on ServerException catch (e) {
    return Left(ServerFailure(e.message, statusCode: e.statusCode));
  } on NetworkException catch (e) {
    return Left(NetworkFailure(e.message));
  } catch (e) {
    return Left(ServerFailure(e.toString()));
  }
}
