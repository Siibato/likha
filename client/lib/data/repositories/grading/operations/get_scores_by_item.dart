import 'package:dartz/dartz.dart';
import 'package:likha/core/errors/failures.dart';
import 'package:likha/core/logging/repo_logger.dart';
import 'package:likha/core/network/server_reachability_service.dart';
import 'package:likha/core/utils/typedef.dart';
import 'package:likha/data/datasources/local/grading/grading_local_datasource.dart';
import 'package:likha/data/datasources/remote/grading/grading_remote_datasource.dart';
import 'package:likha/domain/grading/entities/grade_score.dart';

import '_helpers.dart' as helpers;

ResultFuture<List<GradeScore>> getScoresByItem(
  ServerReachabilityService serverReachabilityService,
  GradingLocalDataSource localDataSource,
  GradingRemoteDataSource remoteDataSource, {
  required String gradeItemId,
}) async {
  RepoLogger.instance.log('getScoresByItem() - gradeItemId=$gradeItemId');
  try {
    RepoLogger.instance.log('getScoresByItem() - Checking local cache first...');
    final cached = await localDataSource.getScoresByItem(gradeItemId);
    
    // If cache has data, return it immediately (offline-first)
    if (cached.isNotEmpty) {
      final entities = cached.map(helpers.scoreToEntity).toList();
      RepoLogger.instance.log('getScoresByItem() - Returning ${entities.length} scores from cache (cache-first)');
      
      // Background sync if server is reachable, but don't wait for it
      if (serverReachabilityService.isServerReachable) {
        RepoLogger.instance.log('getScoresByItem() - Background sync: fetching from remote to update cache...');
        _backgroundSyncScores(
          remoteDataSource,
          localDataSource,
          gradeItemId,
          cached.length,
        );
      }
      
      return Right(entities);
    }
    
    // Cache is empty, try remote
    if (serverReachabilityService.isServerReachable) {
      RepoLogger.instance.log('getScoresByItem() - Cache empty, fetching from remote server...');
      final models = await remoteDataSource.getScoresByItem(
        gradeItemId: gradeItemId,
      );
      
      await localDataSource.saveScores(models);
      
      final entities = models.map(helpers.scoreToEntity).toList();
      return Right(entities);
    } else {
      RepoLogger.instance.log('getScoresByItem() - Cache empty and server not reachable');
      final entities = cached.map(helpers.scoreToEntity).toList();
      return Right(entities);
    }
  } on ServerFailure catch (e) {
    RepoLogger.instance.error('getScoresByItem() - Server failure', e);
    return Left(e);
  } on Failure catch (e) {
    RepoLogger.instance.error('getScoresByItem() - General failure', e);
    return Left(e);
  } catch (e) {
    RepoLogger.instance.error('getScoresByItem() - Unexpected exception', e);
    try {
      final cached = await localDataSource.getScoresByItem(gradeItemId);
      return Right(cached.map(helpers.scoreToEntity).toList());
    } catch (_) {
      return Left(CacheFailure(e.toString()));
    }
  }
}

/// Background sync to update cache without blocking UI
Future<void> _backgroundSyncScores(
  GradingRemoteDataSource remoteDataSource,
  GradingLocalDataSource localDataSource,
  String gradeItemId,
  int currentCacheCount,
) async {
  try {
    final models = await remoteDataSource.getScoresByItem(gradeItemId: gradeItemId);
    RepoLogger.instance.log('_backgroundSyncScores() - Background sync got ${models.length} scores');
    
    // Only update cache if remote has more data than current cache
    if (models.length > currentCacheCount) {
      RepoLogger.instance.log('_backgroundSyncScores() - Updating cache with ${models.length} remote scores');
      await localDataSource.saveScores(models);
    } else {
      RepoLogger.instance.log('_backgroundSyncScores() - Remote has same or fewer scores, keeping cache data');
    }
  } catch (e) {
    RepoLogger.instance.error('_backgroundSyncScores() - Background sync failed', e);
  }
}
