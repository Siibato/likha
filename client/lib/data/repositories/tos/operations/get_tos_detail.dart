import 'package:dartz/dartz.dart';
import 'package:likha/core/errors/exceptions.dart';
import 'package:likha/core/errors/failures.dart';
import 'package:likha/core/events/data_event_bus.dart';
import 'package:likha/core/utils/remote_fetch.dart';
import 'package:likha/core/utils/typedef.dart';
import 'package:likha/data/datasources/local/tos/tos_local_datasource.dart';
import 'package:likha/data/datasources/remote/tos/tos_remote_datasource.dart';
import 'package:likha/domain/tos/entities/tos_entity.dart';

ResultFuture<(TableOfSpecifications, List<TosCompetency>)> getTosDetail(
  TosLocalDataSource localDataSource,
  TosRemoteDataSource remoteDataSource,
  DataEventBus dataEventBus, {
  required String tosId,
}) async {
  try {
    try {
      final localTos = await localDataSource.getTosById(tosId);
      if (localTos != null) {
        final localCompetencies = await localDataSource.getCompetenciesByTos(tosId);
        fireRemoteFetch(
          dedupKey: 'tos/tosDetail/$tosId/bg',
          remote: () => remoteDataSource.getTosDetail(tosId: tosId),
          onSuccess: (fresh) async {
            final (freshTos, freshCompetencies) = fresh;
            try {
              final currentTos = await localDataSource.getTosById(tosId);
              final currentCompetencies = await localDataSource.getCompetenciesByTos(tosId);
              if (_tosDetailHasChanged(currentTos, currentCompetencies, freshTos, freshCompetencies)) {
                await localDataSource.cacheTosList([freshTos]);
                // Safe cache: never overwrites locally-modified rows (needs_sync = 1)
                await localDataSource.cacheCompetencies(tosId, freshCompetencies);
                dataEventBus.notifyTosDetailChanged(tosId);
              }
            } on CacheException {
              await localDataSource.cacheTosList([freshTos]);
              await localDataSource.cacheCompetencies(tosId, freshCompetencies);
              dataEventBus.notifyTosDetailChanged(tosId);
            }
          },
        );
        return Right((localTos, localCompetencies));
      }

      final fresh = await remoteFetch(
        dedupKey: 'tos/tosDetail/$tosId',
        remote: () => remoteDataSource.getTosDetail(tosId: tosId),
      );
      final (tos, competencies) = fresh;
      await localDataSource.cacheTosList([tos]);
      await localDataSource.cacheCompetencies(tosId, competencies);
      return Right((tos, competencies));
    } on CacheException {
      final fresh = await remoteFetch(
        dedupKey: 'tos/tosDetail/$tosId',
        remote: () => remoteDataSource.getTosDetail(tosId: tosId),
      );
      final (tos, competencies) = fresh;
      await localDataSource.cacheTosList([tos]);
      await localDataSource.cacheCompetencies(tosId, competencies);
      return Right((tos, competencies));
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

bool _tosDetailHasChanged(
  TableOfSpecifications? currentTos,
  List<TosCompetency> currentCompetencies,
  TableOfSpecifications freshTos,
  List<TosCompetency> freshCompetencies,
) {
  if (currentTos == null) return true;
  if (currentTos.updatedAt.isBefore(freshTos.updatedAt)) return true;
  if (currentCompetencies.length != freshCompetencies.length) return true;
  final currentIds = {for (final c in currentCompetencies) c.id};
  for (final fc in freshCompetencies) {
    if (!currentIds.contains(fc.id)) return true;
  }
  return false;
}
