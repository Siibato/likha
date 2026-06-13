import 'package:dartz/dartz.dart';
import 'package:likha/core/errors/exceptions.dart';
import 'package:likha/core/errors/failures.dart';
import 'package:likha/core/logging/repo_logger.dart';
import 'package:likha/core/network/server_reachability_service.dart';
import 'package:likha/core/sync/sync_queue.dart';
import 'package:likha/core/utils/typedef.dart';
import 'package:likha/data/datasources/local/auth/auth_local_datasource.dart';
import 'package:likha/data/datasources/remote/auth/auth_remote_datasource.dart';
import 'package:likha/domain/auth/entities/user.dart';
import '_helpers.dart' as helpers;

ResultFuture<List<User>> getAllAccounts(
  ServerReachabilityService serverReachabilityService,
  AuthLocalDataSource localDataSource,
  AuthRemoteDataSource remoteDataSource,
  SyncQueue syncQueue,
) async {
  RepoLogger.instance.log('getAllAccounts START');
  try {
    var cachedAccounts = <User>[];
    bool hasCachedData = false;

    try {
      cachedAccounts = await localDataSource.getCachedAccounts();
      hasCachedData = true;
      RepoLogger.instance.log('getAllAccounts: Found ${cachedAccounts.length} cached accounts');
    } on CacheException {
      hasCachedData = false;
      RepoLogger.instance.log('getAllAccounts: No cached data available');
    }

    RepoLogger.instance.log('getAllAccounts: serverReachable=${serverReachabilityService.isServerReachable}');
    if (serverReachabilityService.isServerReachable) {
      RepoLogger.instance.log('getAllAccounts: Attempting server fetch');
      try {
        final freshAccounts = await remoteDataSource.getAllAccounts();
        RepoLogger.instance.log('getAllAccounts: Server fetch returned ${freshAccounts.length} accounts');
        await localDataSource.cacheAccounts(freshAccounts);
        RepoLogger.instance.log('getAllAccounts: Cached ${freshAccounts.length} accounts locally');

        final pendingAccounts = await helpers.buildPendingAccounts(syncQueue);
        RepoLogger.instance.log('getAllAccounts: Found ${pendingAccounts.length} pending accounts');
        // Final dedup: remove pending accounts that already exist in server accounts
        final serverUsernames = freshAccounts.map((a) => a.username).toSet();
        final deduped = pendingAccounts
            .where((p) => !serverUsernames.contains(p.username))
            .toList();
        final result = [...freshAccounts, ...deduped];
        RepoLogger.instance.log('getAllAccounts: Returning ${result.length} total accounts (server + pending)');
        return Right(result);
      } catch (e) {
        RepoLogger.instance.error('getAllAccounts: Server fetch failed - $e');
        if (!hasCachedData) {
          if (e is ServerException) return Left(ServerFailure(e.message));
          if (e is NetworkException) return Left(NetworkFailure(e.message));
          return Left(ServerFailure(e.toString()));
        }
        // Has cache — fall through
        RepoLogger.instance.log('getAllAccounts: Falling back to cache');
      }
    } else {
      RepoLogger.instance.log('getAllAccounts: Server not reachable, skipping server fetch');
    }

    final pendingAccounts = await helpers.buildPendingAccounts(syncQueue);

    if (hasCachedData) {
      // Final dedup: remove pending accounts that already exist in cached accounts
      final cachedUsernames = cachedAccounts.map((a) => a.username).toSet();
      final deduped = pendingAccounts
          .where((p) => !cachedUsernames.contains(p.username))
          .toList();
      final result = [...cachedAccounts, ...deduped];
      RepoLogger.instance.log('getAllAccounts: Returning ${result.length} accounts from cache + pending');
      return Right(result);
    }

    if (pendingAccounts.isNotEmpty) {
      RepoLogger.instance.log('getAllAccounts: Returning ${pendingAccounts.length} pending accounts only');
      return Right(pendingAccounts);
    }

    RepoLogger.instance.log('getAllAccounts: No data available - returning error');
    return const Left(NetworkFailure('No internet connection and no cached data'));
  } on ServerException catch (e) {
    RepoLogger.instance.error('getAllAccounts: ServerException - ${e.message}');
    return Left(ServerFailure(e.message, statusCode: e.statusCode));
  } on NetworkException catch (e) {
    RepoLogger.instance.error('getAllAccounts: NetworkException - ${e.message}');
    return Left(NetworkFailure(e.message));
  } catch (e) {
    RepoLogger.instance.error('getAllAccounts: Unexpected error - $e');
    return Left(ServerFailure(e.toString()));
  }
}
