import 'package:likha/data/models/auth/activity_log_model.dart';
import 'package:likha/data/models/auth/user_model.dart';
import '../auth_local_datasource_base.dart';
import 'operations/cache/cache_current_user.dart';
import 'operations/cache/cache_accounts.dart';
import 'operations/cache/cache_created_account.dart';
import 'operations/cache/cache_activity_logs.dart';
import 'operations/cache/clear_activity_logs_for_user.dart';
import 'operations/cache/clear_all_cache.dart';

mixin AuthCacheMixin on AuthLocalDataSourceBase {
  @override
  Future<void> cacheCurrentUser(UserModel user) async {
    return cacheCurrentUserOp(localDatabase, enc, user);
  }

  @override
  Future<void> cacheAccounts(List<UserModel> accounts) async {
    return cacheAccountsOp(localDatabase, enc, accounts);
  }

  @override
  Future<void> cacheCreatedAccount(UserModel account) async {
    return cacheCreatedAccountOp(localDatabase, enc, syncQueue, account);
  }

  @override
  Future<void> cacheActivityLogs(List<ActivityLogModel> logs, String userId) async {
    return cacheActivityLogsOp(localDatabase, enc, logs, userId);
  }

  @override
  Future<void> clearActivityLogsForUser(String userId) async {
    return clearActivityLogsForUserOp(localDatabase, userId);
  }

  @override
  Future<void> clearAllCache() async {
    return clearAllCacheOp(localDatabase);
  }
}