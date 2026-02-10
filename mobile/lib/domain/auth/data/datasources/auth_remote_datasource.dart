import 'package:dio/dio.dart';
import 'package:likha/core/constants/api_constants.dart';
import 'package:likha/core/errors/exceptions.dart';
import 'package:likha/core/network/dio_client.dart';
import 'package:likha/domain/auth/data/models/activity_log_model.dart';
import 'package:likha/domain/auth/data/models/auth_response_model.dart';
import 'package:likha/domain/auth/data/models/check_username_result_model.dart';
import 'package:likha/domain/auth/data/models/user_model.dart';
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
      final response = await _dioClient.dio.post(
        ApiConstants.checkUsername,
        data: {'username': username},
      );

      final responseData = response.data['data'] ?? response.data;
      return CheckUsernameResultModel.fromJson(responseData);
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
      final response = await _dioClient.dio.post(
        ApiConstants.activate,
        data: {
          'username': username,
          'password': password,
          'confirm_password': confirmPassword,
        },
      );

      final responseData = response.data['data'] ?? response.data;
      final authResponse = AuthResponseModel.fromJson(responseData);

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
        ApiConstants.login,
        data: {
          'username': username,
          'password': password,
          if (deviceId != null) 'device_id': deviceId,
        },
      );

      final responseData = response.data['data'] ?? response.data;
      final authResponse = AuthResponseModel.fromJson(responseData);

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
      final response = await _dioClient.dio.post(
        ApiConstants.refresh,
        data: {'refresh_token': refreshToken},
      );

      final responseData = response.data['data'] ?? response.data;
      final authResponse = AuthResponseModel.fromJson(responseData);

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
      final response = await _dioClient.dio.get(ApiConstants.me);

      final responseData = response.data['data'] ?? response.data;
      return UserModel.fromJson(responseData);
    } on DioException catch (e) {
      throw _dioClient.handleError(e);
    }
  }

  @override
  Future<void> logout(String refreshToken) async {
    try {
      await _dioClient.dio.post(
        ApiConstants.logout,
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
      final response = await _dioClient.dio.post(
        ApiConstants.accounts,
        data: {
          'username': username,
          'full_name': fullName,
          'role': role,
        },
      );

      final responseData = response.data['data'] ?? response.data;
      return UserModel.fromJson(responseData);
    } on DioException catch (e) {
      throw _dioClient.handleError(e);
    }
  }

  @override
  Future<List<UserModel>> getAllAccounts() async {
    try {
      final response = await _dioClient.dio.get(ApiConstants.accounts);

      final responseData = response.data['data'] ?? response.data;
      final accounts = (responseData['accounts'] as List<dynamic>)
          .map((e) => UserModel.fromJson(e as Map<String, dynamic>))
          .toList();
      return accounts;
    } on DioException catch (e) {
      throw _dioClient.handleError(e);
    }
  }

  @override
  Future<UserModel> resetAccount({required String userId}) async {
    try {
      final response = await _dioClient.dio.post(
        ApiConstants.accountsReset,
        data: {'user_id': userId},
      );

      final responseData = response.data['data'] ?? response.data;
      return UserModel.fromJson(responseData);
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
      final response = await _dioClient.dio.post(
        ApiConstants.accountsLock,
        data: {'user_id': userId, 'locked': locked},
      );

      final responseData = response.data['data'] ?? response.data;
      return UserModel.fromJson(responseData);
    } on DioException catch (e) {
      throw _dioClient.handleError(e);
    }
  }

  @override
  Future<List<ActivityLogModel>> getActivityLogs(
      {required String userId}) async {
    try {
      final response =
          await _dioClient.dio.get(ApiConstants.accountLogs(userId));

      final responseData = response.data['data'] ?? response.data;
      final logs = (responseData['logs'] as List<dynamic>)
          .map((e) => ActivityLogModel.fromJson(e as Map<String, dynamic>))
          .toList();
      return logs;
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

      final response = await _dioClient.dio.put(
        ApiConstants.accountUpdate(userId),
        data: data,
      );

      final responseData = response.data['data'] ?? response.data;
      return UserModel.fromJson(responseData);
    } on DioException catch (e) {
      throw _dioClient.handleError(e);
    }
  }
}
