import 'package:likha/core/database/local_database.dart';
import 'package:likha/core/sync/sync_queue.dart';
import 'package:likha/data/models/auth/user_model.dart';
import 'package:likha/data/models/auth/activity_log_model.dart';
import 'operations/auth.dart' as ops;

abstract class AuthLocalDataSource {
  Future<UserModel> getCachedCurrentUser([String? userId]);
  Future<void> cacheCurrentUser(UserModel user);
  Future<List<UserModel>> getCachedAccounts();
  Future<void> cacheAccounts(List<UserModel> accounts);
  Future<void> cacheCreatedAccount(UserModel account);
  Future<UserModel> getCachedUser(String userId);
  Future<List<ActivityLogModel>> getCachedActivityLogs(String userId);
  Future<void> cacheActivityLogs(List<ActivityLogModel> logs, String userId);
  Future<void> clearActivityLogsForUser(String userId);
  Future<void> deleteAccountLocally(String userId);
  Future<void> clearAllCache();
}

class AuthLocalDataSourceImpl implements AuthLocalDataSource {
  final LocalDatabase localDatabase;
  final SyncQueue syncQueue;

  AuthLocalDataSourceImpl(this.localDatabase, this.syncQueue);

  @override
  Future<UserModel> getCachedCurrentUser([String? userId]) =>
      ops.getCachedCurrentUser(localDatabase, userId);

  @override
  Future<void> cacheCurrentUser(UserModel user) =>
      ops.cacheCurrentUser(localDatabase, user);

  @override
  Future<List<UserModel>> getCachedAccounts() =>
      ops.getCachedAccounts(localDatabase);

  @override
  Future<void> cacheAccounts(List<UserModel> accounts) =>
      ops.cacheAccounts(localDatabase, accounts);

  @override
  Future<void> cacheCreatedAccount(UserModel account) =>
      ops.cacheCreatedAccount(localDatabase, syncQueue, account);

  @override
  Future<UserModel> getCachedUser(String userId) =>
      ops.getCachedUser(localDatabase, userId);

  @override
  Future<List<ActivityLogModel>> getCachedActivityLogs(String userId) =>
      ops.getCachedActivityLogs(localDatabase, userId);

  @override
  Future<void> cacheActivityLogs(List<ActivityLogModel> logs, String userId) =>
      ops.cacheActivityLogs(localDatabase, logs, userId);

  @override
  Future<void> clearActivityLogsForUser(String userId) =>
      ops.clearActivityLogsForUser(localDatabase, userId);

  @override
  Future<void> deleteAccountLocally(String userId) =>
      ops.deleteAccountLocally(localDatabase, userId);

  @override
  Future<void> clearAllCache() =>
      ops.clearAllCache(localDatabase);
}