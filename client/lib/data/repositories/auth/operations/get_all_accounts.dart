import 'package:dartz/dartz.dart';
import 'package:likha/core/errors/exceptions.dart';
import 'package:likha/core/errors/failures.dart';
import 'package:likha/core/logging/repo_logger.dart';
import 'package:likha/core/sync/sync_queue.dart';
import 'package:likha/core/utils/remote_fetch.dart';
import 'package:likha/core/utils/typedef.dart';
import 'package:likha/data/datasources/local/auth/auth_local_datasource.dart';
import 'package:likha/data/datasources/remote/auth/auth_remote_datasource.dart';
import 'package:likha/domain/auth/entities/user.dart';
import '_helpers.dart' as helpers;

bool _accountsHaveChanged(List<User> current, List<User> fresh) {
  if (current.length != fresh.length) return true;
  final currentById = {for (final u in current) u.id: u};
  for (final f in fresh) {
    final c = currentById[f.id];
    if (c == null ||
        c.username != f.username ||
        c.fullName != f.fullName ||
        c.role != f.role ||
        c.accountStatus != f.accountStatus) {
      return true;
    }
  }
  return false;
}

ResultFuture<List<User>> getAllAccounts(
  AuthLocalDataSource localDataSource,
  AuthRemoteDataSource remoteDataSource,
  SyncQueue syncQueue, {
  bool skipBackgroundRefresh = false,
}) async {
  RepoLogger.instance.log('getAllAccounts START');
  try {
    try {
      final cachedAccounts = await localDataSource.getCachedAccounts();
      RepoLogger.instance.log('getAllAccounts: Found ${cachedAccounts.length} cached accounts');

      if (!skipBackgroundRefresh) {
        fireRemoteFetch(
          dedupKey: 'auth/allAccounts/bg',
          remote: remoteDataSource.getAllAccounts,
          onSuccess: (freshAccounts) async {
            RepoLogger.instance.log('getAllAccounts: Background fetch returned ${freshAccounts.length} accounts');
            final current = await localDataSource.getCachedAccounts();
            if (_accountsHaveChanged(current, freshAccounts)) {
              await localDataSource.cacheAccounts(freshAccounts);
            }
          },
        );
      }

      final pendingAccounts = await helpers.buildPendingAccounts(syncQueue);
      final cachedUsernames = cachedAccounts.map((a) => a.username).toSet();
      final deduped = pendingAccounts
          .where((p) => !cachedUsernames.contains(p.username))
          .toList();
      final result = [...cachedAccounts, ...deduped]
        ..sort((a, b) => a.lastName.toLowerCase().compareTo(b.lastName.toLowerCase()));
      RepoLogger.instance.log('getAllAccounts: Returning ${result.length} accounts from cache + pending');
      return Right(result);
    } on CacheException {
      RepoLogger.instance.log('getAllAccounts: No cached data available');

      final freshAccounts = await remoteFetch(
        dedupKey: 'auth/allAccounts',
        remote: remoteDataSource.getAllAccounts,
      );
      await localDataSource.cacheAccounts(freshAccounts);
      RepoLogger.instance.log('getAllAccounts: Cached ${freshAccounts.length} accounts from remote');

      final pendingAccounts = await helpers.buildPendingAccounts(syncQueue);
      final serverUsernames = freshAccounts.map((a) => a.username).toSet();
      final deduped = pendingAccounts
          .where((p) => !serverUsernames.contains(p.username))
          .toList();
      final result = [...freshAccounts, ...deduped]
        ..sort((a, b) => a.lastName.toLowerCase().compareTo(b.lastName.toLowerCase()));
      RepoLogger.instance.log('getAllAccounts: Returning ${result.length} total accounts (remote + pending)');
      return Right(result);
    }
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
