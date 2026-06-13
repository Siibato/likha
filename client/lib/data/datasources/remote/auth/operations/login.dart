import 'package:dio/dio.dart';

import 'package:likha/core/constants/api_endpoints.dart';
import 'package:likha/core/errors/exceptions.dart';
import 'package:likha/core/logging/repo_logger.dart';
import 'package:likha/core/network/dio_client.dart';
import 'package:likha/data/models/auth/auth_response_model.dart';
import 'package:likha/services/storage_service.dart';

Future<AuthResponseModel> login(
  DioClient dioClient,
  StorageService storageService, {
  required String username,
  required String password,
  String? deviceId,
}) async {
  try {
    RepoLogger.instance.log('Login request for username: $username');
    final authResponse = await dioClient.postTyped(
      ApiEndpoints.login,
      data: {
        'username': username,
        'password': password,
        if (deviceId != null) 'device_id': deviceId,
      },
    );

    await storageService.saveAuthData(
      accessToken: authResponse.accessToken,
      refreshToken: authResponse.refreshToken,
      userId: authResponse.user.id,
    );

    RepoLogger.instance.log('Login successful for username: $username');
    return authResponse;
  } on DioException catch (e) {
    RepoLogger.instance.log('DioException in login: ${e.response?.statusCode}, path: ${e.requestOptions.path}');
    if (e.response?.statusCode == 429) {
      final data = e.response?.data;
      final secs = data?['remaining_seconds'] as int? ?? 300;
      RepoLogger.instance.log('429 Too Many Requests - remaining_seconds: $secs');
      throw TooManyRequestsException(
        data?['message'] ?? 'Too many failed attempts',
        remainingSeconds: secs,
      );
    }
    if (e.response?.statusCode == 409) {
      RepoLogger.instance.log('409 Conflict - activation required');
      throw ActivationRequiredException(
        e.response?.data['message'] ?? 'Account requires activation',
        username: username,
      );
    }
    if (e.response?.statusCode == 401) {
      final data = e.response?.data;
      final remaining = data?['attempts_remaining'] as int?;
      RepoLogger.instance.log('401 Unauthorized - attempts_remaining: $remaining');
      if (remaining != null) {
        RepoLogger.instance.log('Throwing InvalidCredentialsException with attemptsRemaining: $remaining');
        throw InvalidCredentialsException(
          data?['message'] ?? 'Invalid password',
          attemptsRemaining: remaining,
        );
      }
    }
    RepoLogger.instance.log('Falling back to handleError for status code: ${e.response?.statusCode}');
    throw dioClient.handleError(e);
  }
}
