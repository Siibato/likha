import 'package:dartz/dartz.dart';

import 'package:likha/core/errors/failures.dart';
import 'package:likha/core/utils/typedef.dart';
import 'package:likha/data/models/tos/melcs_model.dart';
import 'package:likha/domain/tos/entities/tos_entity.dart';
import '../tos_repository_base.dart';

mixin TosQueryMixin on TosRepositoryBase {
  @override
  ResultFuture<List<TableOfSpecifications>> getTosList({
    required String classId,
  }) async {
    try {
      final cached = await localDataSource.getTosByClass(classId);

      if (cached.isNotEmpty) {
        // Has local data — return it immediately and background-refresh.
        if (serverReachabilityService.isServerReachable) {
          _backgroundFetchTosList(classId);
        }
        return Right(cached);
      }

      if (serverReachabilityService.isServerReachable) {
        final models = await remoteDataSource.getTosByClass(classId: classId);
        await localDataSource.cacheTosList(models);
        return Right(models);
      }

      return const Right([]);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  void _backgroundFetchTosList(String classId) async {
    try {
      final models = await remoteDataSource.getTosByClass(classId: classId);
      await localDataSource.cacheTosList(models);
    } catch (_) {
      // Non-fatal: background refresh failure
    }
  }

  @override
  ResultFuture<(TableOfSpecifications, List<TosCompetency>)> getTosDetail({
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
          _backgroundFetchTosDetail(tosId);
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

  void _backgroundFetchTosDetail(String tosId) async {
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

  @override
  ResultFuture<List<MelcEntryModel>> searchMelcs({
    String? subject,
    String? gradeLevel,
    int? quarter,
    String? query,
  }) async {
    try {
      // Local-first
      final local = await localDataSource.searchMelcs(
        subject: subject,
        gradeLevel: gradeLevel,
        quarter: quarter,
        query: query,
      );

      if (local.isNotEmpty) return Right(local);

      // Remote fallback if local is empty and online
      if (serverReachabilityService.isServerReachable) {
        final remote = await remoteDataSource.searchMelcs(
          subject: subject,
          gradeLevel: gradeLevel,
          quarter: quarter,
          query: query,
        );
        return Right(remote);
      }

      return Right(local);
    } on ServerFailure catch (e) {
      return Left(e);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }
}
