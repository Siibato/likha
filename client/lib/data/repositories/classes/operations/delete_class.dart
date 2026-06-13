import 'package:dartz/dartz.dart';
import 'package:likha/core/errors/exceptions.dart';
import 'package:likha/core/errors/failures.dart';
import 'package:likha/core/network/server_reachability_service.dart';
import 'package:likha/core/sync/sync_queue.dart';
import 'package:likha/core/utils/typedef.dart';
import 'package:likha/data/datasources/local/classes/class_local_datasource.dart';
import 'package:likha/data/datasources/remote/classes/class_remote_datasource.dart';
import 'package:uuid/uuid.dart';

ResultVoid deleteClass(
  ServerReachabilityService serverReachabilityService,
  ClassLocalDataSource localDataSource,
  ClassRemoteDataSource remoteDataSource,
  SyncQueue syncQueue, {
  required String classId,
}) async {
  try {
    if (!serverReachabilityService.isServerReachable) {
      await syncQueue.enqueue(SyncQueueEntry(
        id: const Uuid().v4(),
        entityType: SyncEntityType.classEntity,
        operation: SyncOperation.delete,
        payload: {'id': classId},
        status: SyncStatus.pending,
        retryCount: 0,
        maxRetries: 5,
        createdAt: DateTime.now(),
      ));

      try {
        final cached = await localDataSource.getCachedClasses();
        final updated = cached.where((c) => c.id != classId).toList();
        await localDataSource.cacheClasses(updated);
      } catch (_) {}

      return const Right(null);
    }

    await remoteDataSource.deleteClass(classId: classId);

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
