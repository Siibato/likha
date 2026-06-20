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
    String? idempotencyKey,
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
    String? idempotencyKey,
  });

  Future<List<UserModel>> getAllAccounts();

  Future<UserModel> resetAccount({required String userId, String? idempotencyKey});

  Future<UserModel> lockAccount({required String userId, required bool locked, String? reason, String? idempotencyKey});

  Future<List<ActivityLogModel>> getActivityLogs({required String userId});

  Future<UserModel> updateAccount({
    required String userId,
    String? fullName,
    String? role,
    String? idempotencyKey,
  });

  Future<void> deleteAccount({required String userId, String? idempotencyKey});
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
    String? idempotencyKey,
  }) =>
      ops.activateAccount(
        _dioClient,
        _storageService,
        username: username,
        password: password,
        confirmPassword: confirmPassword,
        idempotencyKey: idempotencyKey,
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
    String? idempotencyKey,
  }) =>
      ops.createAccount(
        _dioClient,
        username: username,
        fullName: fullName,
        role: role,
        idempotencyKey: idempotencyKey,
      );

  @override
  Future<List<UserModel>> getAllAccounts() =>
      ops.getAllAccounts(
        _dioClient,
      );

  @override
  Future<UserModel> resetAccount({required String userId, String? idempotencyKey}) =>
      ops.resetAccount(
        _dioClient,
        userId: userId,
        idempotencyKey: idempotencyKey,
      );

  @override
  Future<UserModel> lockAccount({
    required String userId,
    required bool locked,
    String? reason,
    String? idempotencyKey,
  }) =>
      ops.lockAccount(
        _dioClient,
        userId: userId,
        locked: locked,
        reason: reason,
        idempotencyKey: idempotencyKey,
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
    String? idempotencyKey,
  }) =>
      ops.updateAccount(
        _dioClient,
        userId: userId,
        fullName: fullName,
        role: role,
        idempotencyKey: idempotencyKey,
      );

  @override
  Future<void> deleteAccount({required String userId, String? idempotencyKey}) =>
      ops.deleteAccount(
        _dioClient,
        userId: userId,
        idempotencyKey: idempotencyKey,
      );
}
