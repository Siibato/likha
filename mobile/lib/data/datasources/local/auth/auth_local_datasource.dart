import 'package:likha/data/models/auth/user_model.dart';
import 'package:likha/data/models/auth/activity_log_model.dart';

abstract class AuthLocalDataSource {
  Future<UserModel> getCachedCurrentUser();
  Future<void> cacheCurrentUser(UserModel user);
  Future<List<UserModel>> getCachedAccounts();
  Future<void> cacheAccounts(List<UserModel> accounts);
  Future<void> cacheCreatedAccount(UserModel account);
  Future<List<ActivityLogModel>> getCachedActivityLogs(String userId);
  Future<void> cacheActivityLogs(List<ActivityLogModel> logs, String userId);
  Future<void> clearActivityLogsForUser(String userId);
  Future<void> clearAllCache();
}