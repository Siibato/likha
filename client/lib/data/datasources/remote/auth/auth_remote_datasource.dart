import 'package:likha/core/network/dio_client.dart';
import 'package:likha/data/models/auth/activity_log_model.dart';
import 'package:likha/data/models/auth/auth_response_model.dart';
import 'package:likha/data/models/auth/check_username_result_model.dart';
import 'package:likha/data/models/auth/user_model.dart';
import 'package:likha/services/storage_service.dart';
import 'package:likha/data/datasources/remote/auth/operations/auth.dart' as ops;

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
      {required String username}) =>
      ops.checkUsername(
        _dioClient,
        username: username,
      );

  @override
  Future<AuthResponseModel> activateAccount({
    required String username,
    required String password,
    required String confirmPassword,
  }) =>
      ops.activateAccount(
        _dioClient,
        _storageService,
        username: username,
        password: password,
        confirmPassword: confirmPassword,
      );

  @override
  Future<AuthResponseModel> login({
    required String username,
    required String password,
    String? deviceId,
  }) =>
      ops.login(
        _dioClient,
        _storageService,
        username: username,
        password: password,
        deviceId: deviceId,
      );

  @override
  Future<AuthResponseModel> refreshToken(String refreshToken) =>
      ops.refreshToken(
        _dioClient,
        _storageService,
        refreshToken,
      );

  @override
  Future<UserModel> getCurrentUser() =>
      ops.getCurrentUser(
        _dioClient,
      );

  @override
  Future<void> logout(String refreshToken) =>
      ops.logout(
        _dioClient,
        _storageService,
        refreshToken,
      );

  // ===== Admin methods =====

  @override
  Future<UserModel> createAccount({
    required String username,
    required String fullName,
    required String role,
  }) =>
      ops.createAccount(
        _dioClient,
        username: username,
        fullName: fullName,
        role: role,
      );

  @override
  Future<List<UserModel>> getAllAccounts() =>
      ops.getAllAccounts(
        _dioClient,
      );

  @override
  Future<UserModel> resetAccount({required String userId}) =>
      ops.resetAccount(
        _dioClient,
        userId: userId,
      );

  @override
  Future<UserModel> lockAccount({
    required String userId,
    required bool locked,
    String? reason,
  }) =>
      ops.lockAccount(
        _dioClient,
        userId: userId,
        locked: locked,
        reason: reason,
      );

  @override
  Future<List<ActivityLogModel>> getActivityLogs(
      {required String userId}) =>
      ops.getActivityLogs(
        _dioClient,
        userId: userId,
      );

  @override
  Future<UserModel> updateAccount({
    required String userId,
    String? fullName,
    String? role,
  }) =>
      ops.updateAccount(
        _dioClient,
        userId: userId,
        fullName: fullName,
        role: role,
      );

  @override
  Future<void> deleteAccount({required String userId}) =>
      ops.deleteAccount(
        _dioClient,
        userId: userId,
      );
}
