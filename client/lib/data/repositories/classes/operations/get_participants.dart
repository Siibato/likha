import 'package:dartz/dartz.dart';
import 'package:likha/core/errors/exceptions.dart';
import 'package:likha/core/errors/failures.dart';
import 'package:likha/core/events/data_event_bus.dart';
import 'package:likha/core/utils/remote_fetch.dart';
import 'package:likha/core/utils/typedef.dart';
import 'package:likha/data/datasources/local/classes/class_local_datasource.dart';
import 'package:likha/data/datasources/remote/classes/class_remote_datasource.dart';
import 'package:likha/domain/auth/entities/user.dart';

bool _participantsHaveChanged(List<User> current, List<User> fresh) {
  if (current.length != fresh.length) return true;
  final currentIds = current.map((e) => e.id).toSet();
  final freshIds = fresh.map((e) => e.id).toSet();
  return !currentIds.containsAll(freshIds) || !freshIds.containsAll(currentIds);
}

ResultFuture<List<User>> getParticipants(
  ClassLocalDataSource localDataSource,
  ClassRemoteDataSource remoteDataSource,
  DataEventBus dataEventBus, {
  required String classId,
  bool skipBackgroundRefresh = false,
}) async {
  try {
    try {
      final cached = await localDataSource.getCachedParticipants(classId);

      if (!skipBackgroundRefresh) {
        fireRemoteFetch(
          dedupKey: 'classes/participants/$classId/bg',
          remote: () => remoteDataSource.getParticipants(classId: classId),
          onSuccess: (fresh) async {
            final current = await localDataSource.getCachedParticipants(classId);
            if (_participantsHaveChanged(current, fresh)) {
              await localDataSource.cacheParticipants(classId, fresh);
              dataEventBus.notifyParticipantsChanged(classId);
            }
          },
        );
      }
      return Right(cached.cast<User>());
    } on CacheException {
      final fresh = await remoteFetch(
        dedupKey: 'classes/participants/$classId',
        remote: () => remoteDataSource.getParticipants(classId: classId),
      );
      await localDataSource.cacheParticipants(classId, fresh);
      return Right(fresh.cast<User>());
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
