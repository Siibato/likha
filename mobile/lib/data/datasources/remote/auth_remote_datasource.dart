import 'package:dio/dio.dart';
import 'package:likha/core/constants/api_endpoints.dart';
import 'package:likha/core/errors/exceptions.dart';
import 'package:likha/core/network/dio_client.dart';
import 'package:likha/data/models/auth/activity_log_model.dart';
import 'package:likha/data/models/auth/auth_response_model.dart';
import 'package:likha/data/models/auth/check_username_result_model.dart';
import 'package:likha/data/models/auth/user_model.dart';
import 'package:likha/services/storage_service.dart';

abstract class AuthRemoteDataSource {
  Future<CheckUsernameResultModel> checkUsername({required String username});

  Future<AuthResponseModel> activateAccount({
    required String username,
    required String password,
    required String confirmPassword,
  });

  Future<AuthResponseModel> login({
    required String username,
    required String password,
    String? deviceId,
  });

  Future<AuthResponseModel> refreshToken(String refreshToken);

  Future<UserModel> getCurrentUser();

  Future<void> logout(String refreshToken);

  // Admin methods
  Future<UserModel> createAccount({
    required String username,
    required String fullName,
    required String role,
  });

  Future<List<UserModel>> getAllAccounts();

  Future<UserModel> resetAccount({required String userId});

  Future<UserModel> lockAccount({required String userId, required bool locked, String? reason});

  Future<List<ActivityLogModel>> getActivityLogs({required String userId});

  Future<UserModel> updateAccount({
    required String userId,
    String? fullName,
    String? role,
  });

  Future<void> deleteAccount({required String userId});
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final DioClient _dioClient;
  final StorageService _storageService;

  AuthRemoteDataSourceImpl(this._dioClient, this._storageService);

  @override
  Future<CheckUsernameResultModel> checkUsername(
      {required String username}) async {
    try {
      return await _dioClient.postTyped(
        ApiEndpoints.checkUsername,
        data: {'username': username},
      );
    } on DioException catch (e) {
      throw _dioClient.handleError(e);
    }
  }

  @override
  Future<AuthResponseModel> activateAccount({
    required String username,
    required String password,
    required String confirmPassword,
  }) async {
    try {
      final authResponse = await _dioClient.postTyped(
        ApiEndpoints.activate,
        data: {
          'username': username,
          'password': password,
          'confirm_password': confirmPassword,
        },
      );

      await _storageService.saveAuthData(
        accessToken: authResponse.accessToken,
        refreshToken: authResponse.refreshToken,
        userId: authResponse.user.id,
      );

      return authResponse;
    } on DioException catch (e) {
      throw _dioClient.handleError(e);
    }
  }

  @override
  Future<AuthResponseModel> login({
    required String username,
    required String password,
    String? deviceId,
  }) async {
    try {
      final authResponse = await _dioClient.postTyped(
        ApiEndpoints.login,
        data: {
          'username': username,
          'password': password,
          if (deviceId != null) 'device_id': deviceId,
        },
      );

      await _storageService.saveAuthData(
        accessToken: authResponse.accessToken,
        refreshToken: authResponse.refreshToken,
        userId: authResponse.user.id,
      );

      return authResponse;
    } on DioException catch (e) {
      // Handle 429 Too Many Requests (lockout)
      if (e.response?.statusCode == 429) {
        final data = e.response?.data;
        final secs = data?['remaining_seconds'] as int? ?? 300;
        throw TooManyRequestsException(
          data?['message'] ?? 'Too many failed attempts',
          remainingSeconds: secs,
        );
      }
      // Handle 409 Conflict (activation required)
      if (e.response?.statusCode == 409) {
        throw ActivationRequiredException(
          e.response?.data['message'] ?? 'Account requires activation',
          username: username,
        );
      }
      // Handle 401 Unauthorized with attempts_remaining (invalid password)
      if (e.response?.statusCode == 401) {
        final data = e.response?.data;
        final remaining = data?['attempts_remaining'] as int?;
        if (remaining != null) {
          throw InvalidCredentialsException(
            data?['message'] ?? 'Invalid password',
            attemptsRemaining: remaining,
          );
        }
      }
      throw _dioClient.handleError(e);
    }
  }

  @override
  Future<AuthResponseModel> refreshToken(String refreshToken) async {
    try {
      final authResponse = await _dioClient.postTyped(
        ApiEndpoints.refresh,
        data: {'refresh_token': refreshToken},
      );

      await _storageService.saveAuthData(
        accessToken: authResponse.accessToken,
        refreshToken: authResponse.refreshToken,
        userId: authResponse.user.id,
      );

      return authResponse;
    } on DioException catch (e) {
      throw _dioClient.handleError(e);
    }
  }

  @override
  Future<UserModel> getCurrentUser() async {
    try {
      return await _dioClient.getTyped(ApiEndpoints.me);
    } on DioException catch (e) {
      throw _dioClient.handleError(e);
    }
  }

  @override
  Future<void> logout(String refreshToken) async {
    try {
      await _dioClient.postVoid(
        ApiEndpoints.logout,
        data: {'refresh_token': refreshToken},
      );

      await _storageService.clearAuthData();
    } on DioException catch (e) {
      throw _dioClient.handleError(e);
    }
  }

  // ===== Admin methods =====

  @override
  Future<UserModel> createAccount({
    required String username,
    required String fullName,
    required String role,
  }) async {
    try {
      return await _dioClient.postTyped(
        ApiEndpoints.accountsCreate,
        data: {
          'username': username,
          'full_name': fullName,
          'role': role,
        },
      );
    } on DioException catch (e) {
      throw _dioClient.handleError(e);
    }
  }

  @override
  Future<List<UserModel>> getAllAccounts() async {
    try {
      return await _dioClient.getTyped(ApiEndpoints.accountsList);
    } on DioException catch (e) {
      throw _dioClient.handleError(e);
    }
  }

  @override
  Future<UserModel> resetAccount({required String userId}) async {
    try {
      return await _dioClient.postTyped(
        ApiEndpoints.accountsReset,
        data: {'user_id': userId},
      );
    } on DioException catch (e) {
      throw _dioClient.handleError(e);
    }
  }

  @override
  Future<UserModel> lockAccount({
    required String userId,
    required bool locked,
    String? reason,
  }) async {
    try {
      final data = <String, dynamic>{'user_id': userId, 'locked': locked};
      if (reason != null) data['reason'] = reason;
      return await _dioClient.postTyped(
        ApiEndpoints.accountsLock,
        data: data,
      );
    } on DioException catch (e) {
      throw _dioClient.handleError(e);
    }
  }

  @override
  Future<List<ActivityLogModel>> getActivityLogs(
      {required String userId}) async {
    try {
      return await _dioClient.getTyped(ApiEndpoints.accountLogs(userId));
    } on DioException catch (e) {
      throw _dioClient.handleError(e);
    }
  }

  @override
  Future<UserModel> updateAccount({
    required String userId,
    String? fullName,
    String? role,
  }) async {
    try {
      final data = <String, dynamic>{};
      if (fullName != null) data['full_name'] = fullName;
      if (role != null) data['role'] = role;

      return await _dioClient.putTyped(
        ApiEndpoints.accountUpdate(userId),
        data: data,
      );
    } on DioException catch (e) {
      throw _dioClient.handleError(e);
    }
  }

  @override
  Future<void> deleteAccount({required String userId}) async {
    try {
      await _dioClient.deleteTyped(ApiEndpoints.accountDelete(userId));
    } on DioException catch (e) {
      throw _dioClient.handleError(e);
    }
  }
}
