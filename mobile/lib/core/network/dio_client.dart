import 'dart:async';

import 'package:dio/dio.dart';
import 'package:likha/core/constants/api_constants.dart';
import 'package:likha/core/constants/api_endpoint.dart';
import 'package:likha/core/constants/api_endpoints.dart';
import 'package:likha/core/errors/exceptions.dart';
import 'package:likha/core/network/api_response.dart';
import 'package:likha/core/network/server_reachability_interceptor.dart';
import 'package:likha/core/network/server_reachability_service.dart';
import 'package:likha/services/storage_service.dart';

class DioClient {
  final Dio _dio;
  final StorageService _storageService;
  final ServerReachabilityService _serverReachabilityService;

  /// Set this callback to be notified when auth is irrecoverably invalid.
  /// The AuthWrapper hooks into this to force-navigate to the login screen.
  void Function()? onForceLogout;

  bool _isRefreshing = false;
  final List<Completer<bool>> _refreshQueue = [];

  DioClient(this._storageService, this._serverReachabilityService) : _dio = Dio() {
    _dio
      ..options.baseUrl = ApiConstants.baseUrl
      ..options.connectTimeout = ApiConstants.connectTimeout
      ..options.receiveTimeout = ApiConstants.receiveTimeout
      ..options.responseType = ResponseType.json
      ..interceptors.add(ServerReachabilityInterceptor(_serverReachabilityService))
      ..interceptors.add(LogInterceptor(
        request: true,
        requestHeader: true,
        requestBody: true,
        responseHeader: true,
        responseBody: true,
        error: true,
      ))
      ..interceptors.add(_authInterceptor())
      ..interceptors.add(_errorInterceptor());
  }

  Dio get dio => _dio;

  /// Typed GET request that validates the server's ApiResponse<T> envelope.
  /// Throws [ServerException] if success is false.
  Future<T> getTyped<T>(ApiEndpoint<T> endpoint,
      {Map<String, dynamic>? queryParameters}) async {
    try {
      final response = await _dio.get(
        endpoint.path,
        queryParameters: queryParameters,
      );
      return ApiResponse.fromJson(response.data, endpoint.fromJson).unwrap();
    } on DioException catch (e) {
      throw handleError(e);
    }
  }

  /// Typed POST request that validates the server's ApiResponse<T> envelope.
  /// Throws [ServerException] if success is false.
  Future<T> postTyped<T>(ApiEndpoint<T> endpoint, {dynamic data}) async {
    try {
      final response = await _dio.post(
        endpoint.path,
        data: data,
      );
      return ApiResponse.fromJson(response.data, endpoint.fromJson).unwrap();
    } on DioException catch (e) {
      throw handleError(e);
    }
  }

  /// Typed PUT request that validates the server's ApiResponse<T> envelope.
  /// Throws [ServerException] if success is false.
  Future<T> putTyped<T>(ApiEndpoint<T> endpoint, {dynamic data}) async {
    try {
      final response = await _dio.put(
        endpoint.path,
        data: data,
      );
      return ApiResponse.fromJson(response.data, endpoint.fromJson).unwrap();
    } on DioException catch (e) {
      throw handleError(e);
    }
  }

  /// Typed DELETE request that validates the server's ApiResponse envelope.
  /// For void responses, we check the success flag but don't deserialize data.
  /// Throws [ServerException] if success is false.
  Future<void> deleteTyped(ApiEndpoint<void> endpoint) async {
    try {
      final response = await _dio.delete(endpoint.path);
      // Deserialize the envelope but ignore the data (it's void)
      final apiResponse = ApiResponse.fromJson(response.data, (_) {});
      if (!apiResponse.success) {
        throw ServerException(apiResponse.error ?? 'Delete failed');
      }
    } on DioException catch (e) {
      throw handleError(e);
    }
  }

  /// Void POST request — validates server's ApiResponse envelope but ignores data.
  /// Use when the server returns a success/error envelope but no meaningful body.
  /// Mirrors deleteTyped — does NOT call unwrap() to avoid "Response data is null".
  Future<void> postVoid(ApiEndpoint<void> endpoint, {dynamic data}) async {
    try {
      final response = await _dio.post(endpoint.path, data: data);
      final apiResponse = ApiResponse.fromJson(response.data, (_) {});
      if (!apiResponse.success) {
        throw ServerException(apiResponse.error ?? 'Request failed');
      }
    } on DioException catch (e) {
      throw handleError(e);
    }
  }

  /// Void PUT request — validates server's ApiResponse envelope but ignores data.
  /// Use when the server returns a success/error envelope but no meaningful body.
  /// Mirrors deleteTyped — does NOT call unwrap() to avoid "Response data is null".
  Future<void> putVoid(ApiEndpoint<void> endpoint, {dynamic data}) async {
    try {
      final response = await _dio.put(endpoint.path, data: data);
      final apiResponse = ApiResponse.fromJson(response.data, (_) {});
      if (!apiResponse.success) {
        throw ServerException(apiResponse.error ?? 'Request failed');
      }
    } on DioException catch (e) {
      throw handleError(e);
    }
  }

  // Auth Interceptor - Attach token to requests
  Interceptor _authInterceptor() {
    return InterceptorsWrapper(
      onRequest: (options, handler) async {
        // Skip token for auth endpoints
        final publicEndpoints = [
          ApiEndpoints.checkUsername.path,
          ApiEndpoints.activate.path,
          ApiEndpoints.login.path,
          ApiEndpoints.refresh.path,
        ];

        if (!publicEndpoints.contains(options.path)) {
          final token = await _storageService.getAccessToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
        }

        return handler.next(options);
      },
    );
  }

  // Error Interceptor - Handle 401 and auto-refresh
  Interceptor _errorInterceptor() {
    return InterceptorsWrapper(
      onError: (error, handler) async {
        // Only attempt refresh for non-auth endpoints
        if (error.response?.statusCode == 401 &&
            error.requestOptions.path != ApiEndpoints.refresh.path) {
          final refreshed = await _tryRefresh();

          if (refreshed) {
            // Retry the request with the new token
            final options = error.requestOptions;
            final token = await _storageService.getAccessToken();
            options.headers['Authorization'] = 'Bearer $token';

            try {
              final response = await _dio.fetch(options);
              return handler.resolve(response);
            } catch (e) {
              return handler.next(error);
            }
          } else {
            // Refresh failed — force logout
            await _storageService.clearAuthData();
            onForceLogout?.call();
            return handler.next(error);
          }
        }

        return handler.next(error);
      },
    );
  }

  /// Ensures only one refresh attempt runs at a time.
  /// Concurrent callers wait for the same result.
  Future<bool> _tryRefresh() async {
    if (_isRefreshing) {
      // Another refresh is already in flight — wait for its result
      final completer = Completer<bool>();
      _refreshQueue.add(completer);
      return completer.future;
    }

    _isRefreshing = true;
    final success = await _refreshToken();
    _isRefreshing = false;

    // Notify all queued callers
    for (final completer in _refreshQueue) {
      completer.complete(success);
    }
    _refreshQueue.clear();

    return success;
  }

  // Refresh token logic
  Future<bool> _refreshToken() async {
    try {
      final refreshToken = await _storageService.getRefreshToken();
      if (refreshToken == null) return false;

      final response = await _dio.post(
        ApiEndpoints.refresh.path,
        data: {'refresh_token': refreshToken},
      );

      // Validate the ApiResponse envelope structure
      final apiResponse = ApiResponse.fromJson(response.data, (json) => json);
      if (!apiResponse.success || apiResponse.data == null) {
        return false;
      }

      final data = apiResponse.data as Map<String, dynamic>;
      await _storageService.saveAuthData(
        accessToken: data['access_token'] as String,
        refreshToken: data['refresh_token'] as String,
        userId: data['user']['id'] as String,
      );
      return true;
    } catch (e) {
      return false;
    }
  }

  // Helper method to handle API errors
  Exception handleError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return NetworkException('Connection timeout. Please try again.');

      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode;
        final data = error.response?.data;
        final message = (data is Map)
            ? (data['message'] ?? data['detail'] ?? 'Something went wrong')
            : 'Something went wrong';

        if (statusCode == 401) {
          return UnauthorizedException(message);
        }
        return ServerException(message, statusCode: statusCode);

      case DioExceptionType.cancel:
        return ServerException('Request cancelled');

      case DioExceptionType.connectionError:
        return NetworkException('No internet connection');

      default:
        return ServerException('Unexpected error occurred');
    }
  }
}

