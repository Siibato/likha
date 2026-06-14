import 'package:dartz/dartz.dart';
import 'package:likha/core/errors/exceptions.dart';
import 'package:likha/core/errors/failures.dart';
import 'package:likha/core/events/data_event_bus.dart';
import 'package:likha/core/utils/remote_fetch.dart';
import 'package:likha/core/utils/typedef.dart';
import 'package:likha/data/datasources/local/classes/class_local_datasource.dart';
import 'package:likha/data/datasources/remote/classes/class_remote_datasource.dart';
import 'package:likha/domain/auth/entities/user.dart';

bool _searchResultsHaveChanged(List<User> current, List<User> fresh) {
  if (current.length != fresh.length) return true;
  final currentIds = current.map((e) => e.id).toSet();
  final freshIds = fresh.map((e) => e.id).toSet();
  return !currentIds.containsAll(freshIds) || !freshIds.containsAll(currentIds);
}

ResultFuture<List<User>> searchStudents(
  ClassLocalDataSource localDataSource,
  ClassRemoteDataSource remoteDataSource,
  DataEventBus dataEventBus, {
  String? query,
  bool skipBackgroundRefresh = false,
}) async {
  try {
    try {
      final cached = await localDataSource.searchCachedStudents(query ?? '');

      if (!skipBackgroundRefresh) {
        fireRemoteFetch(
          dedupKey: 'classes/searchStudents/${query ?? 'all'}/bg',
          remote: () => remoteDataSource.searchStudents(query: query),
          onSuccess: (fresh) async {
            final current = await localDataSource.searchCachedStudents(query ?? '');
            if (_searchResultsHaveChanged(current, fresh)) {
              await localDataSource.cacheSearchStudents(fresh);
            }
          },
        );
      }

      return Right(cached);
    } on CacheException {
      final fresh = await remoteFetch(
        dedupKey: 'classes/searchStudents/${query ?? 'all'}',
        remote: () => remoteDataSource.searchStudents(query: query),
      );
      try {
        await localDataSource.cacheSearchStudents(fresh);
      } catch (_) {
        // Caching failure must not block the online result
      }
      return Right(fresh);
    }
  } on ServerException catch (e) {
    return Left(ServerFailure(e.message));
  } on NetworkException catch (e) {
    return Left(NetworkFailure(e.message));
  } catch (e) {
    return Left(ServerFailure(e.toString()));
  }
}
