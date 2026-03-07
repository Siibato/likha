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
  }) async {
    try {
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
      return Left(ServerFailure(e.message));
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
  }) async {
    try {
      if (!serverReachabilityService.isServerReachable) {
        await syncQueue.enqueue(SyncQueueEntry(
          id: const Uuid().v4(),
          entityType: SyncEntityType.classEntity,
          operation: SyncOperation.update,
          payload: {
            'id': classId,
            'title': title,
            'description': description,
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

          return Right(ClassEntity(
            id: current.id,
            title: title ?? current.title,
            description: description ?? current.description,
            teacherId: current.teacherId,
            teacherUsername: current.teacherUsername,
            teacherFullName: current.teacherFullName,
            isArchived: current.isArchived,
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
      );

      syncInBackgroundForClass(classId);

      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}