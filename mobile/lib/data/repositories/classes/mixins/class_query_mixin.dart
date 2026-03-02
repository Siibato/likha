import 'package:dartz/dartz.dart';
import 'package:likha/core/errors/exceptions.dart';
import 'package:likha/core/errors/failures.dart';
import 'package:likha/core/utils/typedef.dart';
import 'package:likha/data/repositories/classes/class_repository_base.dart';
import 'package:likha/domain/classes/entities/class_detail.dart';
import 'package:likha/domain/classes/entities/class_entity.dart';

mixin ClassQueryMixin on ClassRepositoryBase {
  @override
  ResultFuture<List<ClassEntity>> getAllClasses() async {
    try {
      try {
        final cachedClasses = await localDataSource.getCachedClasses();

        _syncAllClassesInBackground();

        return Right(cachedClasses);
      } on CacheException {
        final freshClasses = await remoteDataSource.getAllClasses();
        await localDataSource.cacheClasses(freshClasses);

        for (final cls in freshClasses) {
          try {
            final detail = await remoteDataSource.getClassDetail(classId: cls.id);
            await localDataSource.cacheClassDetail(detail);
          } catch (_) {
            // Best-effort
          }
        }

        return Right(freshClasses);
      }
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  ResultFuture<List<ClassEntity>> getMyClasses() async {
    try {
      final currentUserId = await getCurrentUserId();

      try {
        final cachedClasses = await localDataSource.getCachedClasses(
          teacherId: currentUserId,
        );

        _syncClassesInBackground();

        return Right(cachedClasses);
      } on CacheException {
        final freshClasses = await remoteDataSource.getMyClasses();
        await localDataSource.cacheClasses(freshClasses);

        for (final cls in freshClasses) {
          try {
            final detail = await remoteDataSource.getClassDetail(classId: cls.id);
            await localDataSource.cacheClassDetail(detail);
          } catch (_) {
            // Best-effort
          }
        }

        return Right(freshClasses);
      }
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  ResultFuture<ClassDetail> getClassDetail({required String classId}) async {
    try {
      try {
        final fresh = await remoteDataSource.getClassDetail(classId: classId);
        await localDataSource.cacheClassDetail(fresh);
        return Right(fresh);
      } on NetworkException {
        try {
          final cached = await localDataSource.getCachedClassDetail(classId);
          return Right(cached);
        } on CacheException {
          try {
            final rebuilt = await localDataSource.buildClassDetailFromEnrollments(classId);
            if (rebuilt != null) return Right(rebuilt);
            return const Left(CacheFailure('Class detail not available offline'));
          } catch (_) {
            return const Left(CacheFailure('Failed to load class detail offline'));
          }
        }
      }
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  Future<void> _syncAllClassesInBackground() async {
    try {
      final remoteClasses = await remoteDataSource.getAllClasses();

      await entitySyncHelper.syncEntitiesByTimestamp(
        entityType: 'class',
        remoteEntities: remoteClasses
            .map((e) => {
                  'id': e.id,
                  'updated_at': e.updatedAt.toIso8601String(),
                })
            .toList(),
      );

      await localDataSource.cacheClasses(remoteClasses);

      for (final cls in remoteClasses) {
        try {
          final detail = await remoteDataSource.getClassDetail(classId: cls.id);
          await localDataSource.cacheClassDetail(detail);
        } catch (_) {
          // Best-effort
        }
      }
    } catch (_) {
      // Best-effort sync — continue with cached data
    }
  }

  Future<void> _syncClassesInBackground() async {
    try {
      final remoteClasses = await remoteDataSource.getMyClasses();

      await entitySyncHelper.syncEntitiesByTimestamp(
        entityType: 'class',
        remoteEntities: remoteClasses
            .map((e) => {
                  'id': e.id,
                  'updated_at': e.updatedAt.toIso8601String(),
                })
            .toList(),
      );

      await localDataSource.cacheClasses(remoteClasses);

      for (final cls in remoteClasses) {
        try {
          final detail = await remoteDataSource.getClassDetail(classId: cls.id);
          await localDataSource.cacheClassDetail(detail);
        } catch (_) {
          // Best-effort
        }
      }
    } catch (_) {
      // Best-effort sync — continue with cached data
    }
  }
}