import 'dart:async';

import 'package:dio/dio.dart';
import 'package:likha/core/network/server_reachability_service.dart';

/// Dio interceptor that gates requests behind server reachability state.
/// Must be registered as the FIRST interceptor in DioClient.
class ServerReachabilityInterceptor extends Interceptor {
  final ServerReachabilityService _reachabilityService;

  // Prevents burst of failing requests from each triggering checkNow().
  bool _isCheckingNow = false;

  // Only gate requests AFTER the first health check has completed.
  // This prevents false "no internet" errors on app startup.
  bool _hasCheckedOnce = false;

  static const String _healthPath = '/api/v1/health';

  ServerReachabilityInterceptor(this._reachabilityService) {
    // Subscribe to reachability stream to know when first check completes
    _reachabilityService.onServerReachabilityChanged.listen((_) {
      _hasCheckedOnce = true;
    });
  }

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    // Never gate health checks — would cause infinite loop.
    if (options.path == _healthPath) {
      return handler.next(options);
    }

    // Only gate requests AFTER the first health check has completed.
    // This prevents false "no internet" errors on app startup before we know
    // the actual server reachability status.
    if (_hasCheckedOnce && !_reachabilityService.isServerReachable) {
      // Immediately reject with connectionError — DioClient.handleError()
      // maps this to NetworkException, which triggers repository offline paths.
      return handler.reject(
        DioException(
          requestOptions: options,
          type: DioExceptionType.connectionError,
          message: 'Server is unreachable',
        ),
        true, // pass through onError interceptors
      );
    }

    return handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (err.requestOptions.path == _healthPath) {
      return handler.next(err);
    }

    // Connection failure mid-request: trigger immediate health check to update
    // the reachability state for all subsequent requests.
    final isConnectionFailure =
        err.type == DioExceptionType.connectionError ||
        err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.sendTimeout ||
        err.type == DioExceptionType.receiveTimeout;

    if (isConnectionFailure && !_isCheckingNow) {
      _isCheckingNow = true;
      unawaited(
        _reachabilityService.checkNow().whenComplete(() {
          _isCheckingNow = false;
        }),
      );
    }

    return handler.next(err);
  }
}
