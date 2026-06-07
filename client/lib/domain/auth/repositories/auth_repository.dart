import 'package:likha/core/utils/typedef.dart';
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
  ResultFuture<User> createAccount({
    required String username,
    required String fullName,
    required String role,
  });

  ResultFuture<List<User>> getAllAccounts();

  ResultFuture<User> resetAccount({required String userId});

  ResultFuture<User> lockAccount({required String userId, required bool locked, String? reason});

  ResultFuture<List<ActivityLog>> getActivityLogs({required String userId});

  ResultFuture<User> updateAccount({
    required String userId,
    String? fullName,
    String? role,
  });

  ResultVoid deleteAccount({required String userId});
}
