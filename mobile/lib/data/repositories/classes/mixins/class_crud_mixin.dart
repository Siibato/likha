import 'package:dartz/dartz.dart';
import 'package:likha/core/errors/exceptions.dart';
import 'package:likha/core/errors/failures.dart';
import 'package:likha/core/sync/sync_queue.dart';
import 'package:likha/core/utils/typedef.dart';
import 'package:likha/data/models/classes/class_model.dart';
import 'package:likha/data/repositories/classes/class_repository_base.dart';
import 'package:likha/domain/classes/entities/class_entity.dart';
import 'package:uuid/uuid.dart';

mixin ClassCrudMixin on ClassRepositoryBase {
  @override
  ResultFuture<ClassEntity> createClass({
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
          final currentUserId = await getCurrentUserId();
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

      syncInBackgroundForClass(result.id);

      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message, statusCode: e.statusCode));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  ResultVoid deleteClass({required String classId}) async {
    try {
      await remoteDataSource.deleteClass(classId: classId);

      // Remove from local cache
      try {
        final cached = await localDataSource.getCachedClasses();
        final updated = cached.where((c) => c.id != classId).toList();
        await localDataSource.cacheClasses(updated);
      } catch (_) {}

      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message, statusCode: e.statusCode));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  ResultFuture<ClassEntity> updateClass({
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

      final result = await remoteDataSource.updateClass(
        classId: classId,
        title: title,
        description: description,
        teacherId: teacherId,
        isAdvisory: isAdvisory,
      );

      syncInBackgroundForClass(classId);

      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message, statusCode: e.statusCode));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}