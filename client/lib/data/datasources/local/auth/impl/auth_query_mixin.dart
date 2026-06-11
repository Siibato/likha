import 'package:likha/data/models/auth/activity_log_model.dart';
import 'package:likha/data/models/auth/user_model.dart';
import '../auth_local_datasource_base.dart';
import 'operations/query/get_cached_current_user.dart';
import 'operations/query/get_cached_accounts.dart';
import 'operations/query/get_cached_user.dart';
import 'operations/query/get_cached_activity_logs.dart';

mixin AuthQueryMixin on AuthLocalDataSourceBase {
  @override
  Future<UserModel> getCachedCurrentUser([String? userId]) async {
    return getCachedCurrentUserOp(localDatabase, userId);
  }

  @override
  Future<List<UserModel>> getCachedAccounts() async {
    return getCachedAccountsOp(localDatabase);
  }

  @override
  Future<UserModel> getCachedUser(String userId) async {
    return getCachedUserOp(localDatabase, userId);
  }

  @override
  Future<List<ActivityLogModel>> getCachedActivityLogs(String userId) async {
    return getCachedActivityLogsOp(localDatabase, userId);
  }
}