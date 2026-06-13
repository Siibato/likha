import 'package:dartz/dartz.dart';
import 'package:likha/core/errors/exceptions.dart';
import 'package:likha/core/errors/failures.dart';
import 'package:likha/core/utils/typedef.dart';
import 'package:likha/data/datasources/local/classes/class_local_datasource.dart';
import 'package:likha/data/datasources/remote/classes/class_remote_datasource.dart';
import 'package:likha/domain/classes/entities/class_detail.dart';

ResultFuture<ClassDetail> getClassDetail(
  ClassLocalDataSource localDataSource,
  ClassRemoteDataSource remoteDataSource, {
  required String classId,
}) async {
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
          final rebuilt = await localDataSource.buildClassDetailFromParticipants(classId);
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
