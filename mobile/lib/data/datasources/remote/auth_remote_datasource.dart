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

  Future<UserModel> lockAccount({required String userId, required bool locked});

  Future<List<ActivityLogModel>> getActivityLogs({required String userId});

  Future<UserModel> updateAccount({
    required String userId,
    String? username,
    String? fullName,
  });
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
      final response = await _dioClient.dio.post(
        ApiEndpoints.login.path,
        data: {
          'username': username,
          'password': password,
          if (deviceId != null) 'device_id': deviceId,
        },
      );

      final responseData = response.data['data'] ?? response.data;
      final authResponse = ApiEndpoints.login.fromJson(responseData);

      await _storageService.saveAuthData(
        accessToken: authResponse.accessToken,
        refreshToken: authResponse.refreshToken,
        userId: authResponse.user.id,
      );

      return authResponse;
    } on DioException catch (e) {
      // Handle 409 Conflict (activation required)
      if (e.response?.statusCode == 409) {
        throw ActivationRequiredException(
          e.response?.data['message'] ?? 'Account requires activation',
          username: username,
        );
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
      await _dioClient.postTyped(
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
  }) async {
    try {
      return await _dioClient.postTyped(
        ApiEndpoints.accountsLock,
        data: {'user_id': userId, 'locked': locked},
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
    String? username,
    String? fullName,
  }) async {
    try {
      final data = <String, dynamic>{};
      if (username != null) data['username'] = username;
      if (fullName != null) data['full_name'] = fullName;

      return await _dioClient.putTyped(
        ApiEndpoints.accountUpdate(userId),
        data: data,
      );
    } on DioException catch (e) {
      throw _dioClient.handleError(e);
    }
  }
}
