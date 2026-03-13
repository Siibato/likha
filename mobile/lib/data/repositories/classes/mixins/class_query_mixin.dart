import 'package:dartz/dartz.dart';
import 'package:likha/core/errors/exceptions.dart';
import 'package:likha/core/errors/failures.dart';
import 'package:likha/core/utils/typedef.dart';
import 'package:likha/data/repositories/classes/class_repository_base.dart';
import 'package:likha/domain/classes/entities/class_detail.dart';
import 'package:likha/domain/classes/entities/class_entity.dart';

mixin ClassQueryMixin on ClassRepositoryBase {
  @override
  ResultFuture<List<ClassEntity>> getAllClasses({bool skipBackgroundRefresh = false}) async {
    try {
      try {
        final cachedClasses = await localDataSource.getCachedClasses();
        // Cache hit: return immediately, fire background refresh
        if (!skipBackgroundRefresh) {
          _backgroundFetchAllClasses();
        }
        return Right(cachedClasses);
      } on CacheException {
        // Cache miss: blocking remote fetch (avoids empty-state flash)
        final freshClasses = await remoteDataSource.getAllClasses();
        await localDataSource.cacheClasses(freshClasses);
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
  ResultFuture<List<ClassEntity>> getMyClasses({bool skipBackgroundRefresh = false}) async {
    try {
      final currentUserId = await getCurrentUserId();
      if (currentUserId == null) return const Right([]);

      try {
        // Works for both students (enrolled via class_participants) and
        // teachers (also present in class_participants with role='teacher')
        final cachedClasses = await localDataSource.getCachedClassesForUser(currentUserId);
        // Cache hit: return immediately, fire background refresh
        if (!skipBackgroundRefresh) {
          _backgroundFetchMyClasses();
        }
        return Right(cachedClasses);
      } on CacheException {
        // Cache miss: blocking remote fetch (avoids empty-state flash)
        final freshClasses = await remoteDataSource.getMyClasses();
        await localDataSource.cacheClasses(freshClasses);
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
      // API-first: always get fresh data when online (ensures enrollment data is current)
      try {
        final fresh = await remoteDataSource.getClassDetail(classId: classId);
        await localDataSource.cacheClassDetail(fresh);
        return Right(fresh);
      } on NetworkException {
        // Offline: fall back to cache (which has enrollment data from prior online visit)
        try {
          final cached = await localDataSource.getCachedClassDetail(classId);
          return Right(cached);
        } on CacheException {
          // No cache: try rebuilding from enrollments table
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

  /// Silently fetches fresh classes from the server in background.
  /// Updates local cache only if any record has a newer [updatedAt].
  /// Emits a DataEventBus event so the page can reload from updated cache.
  /// All errors are swallowed — users keep seeing stale cache without error.
  void _backgroundFetchMyClasses() {
    Future.microtask(() async {
      try {
        final fresh = await remoteDataSource.getMyClasses();
        final currentUserId = await getCurrentUserId();
        if (currentUserId == null) return;
        final List<ClassEntity> cached;
        try {
          cached = await localDataSource.getCachedClassesForUser(currentUserId);
        } on CacheException {
          await localDataSource.cacheClasses(fresh);
          dataEventBus.notifyClassesChanged();
          return;
        }
        if (_classesHaveChanged(cached, fresh)) {
          await localDataSource.cacheClasses(fresh);
          dataEventBus.notifyClassesChanged();
        }
      } catch (_) {}
    });
  }

  /// Silently fetches fresh classes from the server in background (admin mode).
  /// Updates local cache only if any record has a newer [updatedAt].
  /// Emits a DataEventBus event so the page can reload from updated cache.
  /// All errors are swallowed — users keep seeing stale cache without error.
  void _backgroundFetchAllClasses() {
    Future.microtask(() async {
      try {
        final fresh = await remoteDataSource.getAllClasses();
        final List<ClassEntity> cached;
        try {
          cached = await localDataSource.getCachedClasses();
        } on CacheException {
          await localDataSource.cacheClasses(fresh);
          dataEventBus.notifyClassesChanged();
          return;
        }
        if (_classesHaveChanged(cached, fresh)) {
          await localDataSource.cacheClasses(fresh);
          dataEventBus.notifyClassesChanged();
        }
      } catch (_) {}
    });
  }

  bool _classesHaveChanged(List<ClassEntity> local, List<ClassEntity> remote) {
    if (local.length != remote.length) return true;
    final localById = {for (final c in local) c.id: c};
    for (final r in remote) {
      final l = localById[r.id];
      if (l == null) return true;
      if (l.updatedAt.isBefore(r.updatedAt)) return true;
    }
    return false;
  }

}