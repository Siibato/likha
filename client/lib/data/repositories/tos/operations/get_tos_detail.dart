import 'package:dartz/dartz.dart';
import 'package:likha/core/errors/failures.dart';
import 'package:likha/core/network/server_reachability_service.dart';
import 'package:likha/core/utils/typedef.dart';
import 'package:likha/data/datasources/local/tos/tos_local_datasource.dart';
import 'package:likha/data/datasources/remote/tos/tos_remote_datasource.dart';
import 'package:likha/domain/tos/entities/tos_entity.dart';

ResultFuture<(TableOfSpecifications, List<TosCompetency>)> getTosDetail(
  ServerReachabilityService serverReachabilityService,
  TosLocalDataSource localDataSource,
  TosRemoteDataSource remoteDataSource, {
  required String tosId,
}) async {
  try {
    // Cache-first: return local data immediately so locally-added competencies
    // are visible even before they have synced to the server.
    final localTos = await localDataSource.getTosById(tosId);
    if (localTos != null) {
      final localCompetencies =
          await localDataSource.getCompetenciesByTos(tosId);
      // Background-refresh from server if online (won't overwrite local edits)
      if (serverReachabilityService.isServerReachable) {
        _backgroundFetchTosDetail(serverReachabilityService, localDataSource, remoteDataSource, tosId);
      }
      return Right((localTos, localCompetencies));
    }

    // No local data — fetch from remote (initial load or first-time open)
    if (serverReachabilityService.isServerReachable) {
      final (tos, competencies) = await remoteDataSource.getTosDetail(
        tosId: tosId,
      );
      await localDataSource.cacheTosList([tos]);
      await localDataSource.cacheCompetencies(tosId, competencies);
      return Right((tos, competencies));
    }

    return const Left(CacheFailure('TOS not found in cache'));
  } catch (e) {
    // Cache fallback on any error
    try {
      final tos = await localDataSource.getTosById(tosId);
      if (tos == null) return const Left(CacheFailure('TOS not found'));
      final competencies =
          await localDataSource.getCompetenciesByTos(tosId);
      return Right((tos, competencies));
    } catch (_) {
      return Left(CacheFailure(e.toString()));
    }
  }
}

void _backgroundFetchTosDetail(
  ServerReachabilityService serverReachabilityService,
  TosLocalDataSource localDataSource,
  TosRemoteDataSource remoteDataSource,
  String tosId,
) async {
  try {
    final (tos, competencies) =
        await remoteDataSource.getTosDetail(tosId: tosId);
    await localDataSource.cacheTosList([tos]);
    // Safe cache: never overwrites locally-modified rows (needs_sync = 1)
    await localDataSource.cacheCompetencies(tosId, competencies);
  } catch (_) {
    // Non-fatal: background refresh failure
  }
}
