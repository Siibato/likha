import 'package:likha/core/sync/mutation_result.dart';
import 'package:likha/core/utils/typedef.dart';
import 'package:likha/data/models/auth/account_detail_response_model.dart';
import 'package:likha/domain/auth/entities/activity_log.dart';
import 'package:likha/domain/auth/entities/check_username_result.dart';
import 'package:likha/domain/auth/entities/user.dart';

abstract class AuthRepository {
  ResultFuture<CheckUsernameResult> checkUsername({required String username});

  ResultFuture<User> activateAccount({
    required String username,
    required String password,
    required String confirmPassword,
  });

  ResultFuture<User> login({
    required String username,
    required String password,
    String? deviceId,
  });

  ResultFuture<User> refreshToken();

  ResultFuture<User> getCurrentUser();

  ResultVoid logout();

  Future<bool> isAuthenticated();

  // Admin methods
  ResultFuture<MutationResult<User>> createAccount({
    required String username,
    required String firstName,
    required String lastName,
    required String role,
    Map<String, dynamic>? learnerDetails,
    Map<String, dynamic>? teacherDetails,
  });

  ResultFuture<List<User>> getAllAccounts({bool skipBackgroundRefresh = false});

  ResultFuture<MutationResult<User>> resetAccount({required String userId});

  ResultFuture<MutationResult<User>> lockAccount({required String userId, required bool locked, String? reason});

  ResultFuture<List<ActivityLog>> getActivityLogs({required String userId});

  ResultFuture<MutationResult<User>> updateAccount({
    required String userId,
    String? firstName,
    String? lastName,
    String? role,
  });

  ResultVoid deleteAccount({required String userId});

  ResultFuture<AccountDetailResponseModel> getAccountDetails({required String userId});

  ResultFuture<AccountDetailResponseModel> upsertAccountDetails({
    required String userId,
    Map<String, dynamic>? learnerDetails,
    Map<String, dynamic>? teacherDetails,
  });
}
