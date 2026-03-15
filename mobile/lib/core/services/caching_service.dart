import 'dart:async';

import 'package:likha/core/errors/exceptions.dart';
import 'package:likha/core/network/connectivity_service.dart';

/// A generic service that implements the online-first caching pattern.
///
/// This service handles:
/// 1. Checking online/offline status
/// 2. Attempting remote fetch if online
/// 3. Caching successfully fetched data
/// 4. Falling back to local cache on network failure
/// 5. Allowing exceptions to bubble up for repository handling
class CachingService {
  final ConnectivityService _connectivityService;

  CachingService(this._connectivityService);

  /// Fetches data with online-first strategy and offline cache fallback.
  ///
  /// The flow is:
  /// 1. If online: attempt [remoteCall], cache result if successful, return it
  /// 2. If online but [remoteCall] throws NetworkException: fall through to cache
  /// 3. If offline or after network failure: attempt [localCall]
  /// 4. All other exceptions (ServerException, CacheException) bubble up
  ///
  /// Parameters:
  /// - [remoteCall]: Function that fetches from remote source
  /// - [cacheFn]: Function that caches the result (fire-and-forget)
  /// - [localCall]: Function that fetches from local cache
  ///
  /// Returns: The fetched data (either from remote or cache)
  ///
  /// Throws:
  /// - ServerException: If remote fetch fails with server error
  /// - CacheException: If offline and cache retrieval fails
  /// - Any other exception from the called functions
  Future<T> fetchWithCache<T>({
    required Future<T> Function() remoteCall,
    required Future<void> Function(T) cacheFn,
    required Future<T> Function() localCall,
  }) async {
    // Online-first routing with fallback to offline cache
    if (_connectivityService.isOnline) {
      try {
        final result = await remoteCall();
        // Fire-and-forget cache update
        unawaited(cacheFn(result));
        return result;
      } on NetworkException catch (_) {
        // Flaky connection - fall through to cache
      } catch (e) {
        // ServerException or other errors bubble up
        rethrow;
      }
    }

    // Offline or network failure - use cached data
    return await localCall();
  }
}
