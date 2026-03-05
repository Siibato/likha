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
        return Right(cachedClasses);
      } on CacheException {
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
  ResultFuture<List<ClassEntity>> getMyClasses() async {
    try {
      final currentUserId = await getCurrentUserId();

      try {
        final cachedClasses = await localDataSource.getCachedClasses(
          teacherId: currentUserId,
        );

        return Right(cachedClasses);
      } on CacheException {
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
      // Try cache first (includes locally-added enrollments that haven't synced yet)
      try {
        final cached = await localDataSource.getCachedClassDetail(classId);
        return Right(cached);
      } on CacheException {
        // No cache, fetch fresh from server
        try {
          final fresh = await remoteDataSource.getClassDetail(classId: classId);
          await localDataSource.cacheClassDetail(fresh);
          return Right(fresh);
        } on NetworkException {
          // No cache and no network, try rebuilding from enrollments
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

}