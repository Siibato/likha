import 'package:dartz/dartz.dart';
import 'package:likha/core/errors/exceptions.dart';
import 'package:likha/core/errors/failures.dart';
import 'package:likha/core/utils/remote_fetch.dart';
import 'package:likha/core/utils/typedef.dart';
import 'package:likha/data/datasources/local/classes/class_local_datasource.dart';
import 'package:likha/data/datasources/remote/classes/class_remote_datasource.dart';
import 'package:likha/domain/classes/entities/class_entity.dart';
import '_helpers.dart' as helpers;

ResultFuture<List<ClassEntity>> getMyClasses(
  ClassLocalDataSource localDataSource,
  ClassRemoteDataSource remoteDataSource, {
  bool skipBackgroundRefresh = false,
}) async {
  try {
    final currentUserId = await helpers.getCurrentUserId();
    if (currentUserId == null) return const Right([]);

    final userRole = await helpers.getCurrentUserRole();
    final isStudent = userRole == 'student';

    try {
      final cachedClasses = await localDataSource.getCachedClassesForUser(currentUserId);

      if (!skipBackgroundRefresh) {
        fireRemoteFetch(
          dedupKey: 'classes/myClasses/$currentUserId/bg',
          remote: remoteDataSource.getMyClasses,
          onSuccess: (fresh) async {
            final current = await localDataSource.getCachedClassesForUser(currentUserId);
            if (helpers.classesHaveChanged(current, fresh)) {
              await localDataSource.cacheClasses(fresh);
              await helpers.cacheStudentParticipations(localDataSource, fresh, currentUserId);
            }
          },
        );
      }
      final classes = isStudent
          ? cachedClasses.where((c) => !c.isAdvisory).toList()
          : cachedClasses;
      return Right(classes);
    } on CacheException {
      final freshClasses = await remoteFetch(
        dedupKey: 'classes/myClasses/$currentUserId',
        remote: remoteDataSource.getMyClasses,
      );
      final classes = isStudent
          ? freshClasses.where((c) => !c.isAdvisory).toList()
          : freshClasses;
      await localDataSource.cacheClasses(classes);
      await helpers.cacheStudentParticipations(localDataSource, classes, currentUserId);
      return Right(classes);
    }
  } on ServerException catch (e) {
    return Left(ServerFailure(e.message, statusCode: e.statusCode));
  } on NetworkException catch (e) {
    return Left(NetworkFailure(e.message));
  } on CacheException catch (e) {
    return Left(CacheFailure(e.message));
  } catch (e) {
    return Left(ServerFailure(e.toString()));
  }
}
