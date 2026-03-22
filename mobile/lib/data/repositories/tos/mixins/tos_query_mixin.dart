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
      // Cache-first: return local data
      final cached = await localDataSource.getTosByClass(classId);

      // Background refresh if online
      if (serverReachabilityService.isServerReachable) {
        _backgroundFetchTosList(classId);
      }

      return Right(cached);
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
      if (serverReachabilityService.isServerReachable) {
        final (tos, competencies) = await remoteDataSource.getTosDetail(
          tosId: tosId,
        );
        await localDataSource.cacheTosList([tos]);
        await localDataSource.cacheCompetencies(tosId, competencies);
        return Right((tos, competencies));
      }

      // Offline fallback
      final tos = await localDataSource.getTosById(tosId);
      if (tos == null) {
        return const Left(CacheFailure('TOS not found in cache'));
      }
      final competencies = await localDataSource.getCompetenciesByTos(tosId);
      return Right((tos, competencies));
    } on ServerFailure catch (e) {
      return Left(e);
    } catch (e) {
      // Try cache fallback
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
