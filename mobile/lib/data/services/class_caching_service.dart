import 'dart:async';

import 'package:likha/core/errors/exceptions.dart';
import 'package:likha/core/network/server_reachability_service.dart';
import 'package:likha/data/datasources/local/classes/class_local_datasource.dart';
import 'package:likha/data/datasources/remote/class_remote_datasource.dart';
import 'package:likha/domain/classes/entities/class_detail.dart';
import 'package:likha/domain/classes/entities/class_entity.dart';

/// Domain-specific caching service for classes.
class ClassCachingService {
  final ClassRemoteDataSource _remoteDataSource;
  final ClassLocalDataSource _localDataSource;
  final ServerReachabilityService _serverReachabilityService;

  ClassCachingService(
    this._remoteDataSource,
    this._localDataSource,
    this._serverReachabilityService,
  );

  /// Fetches user's classes with online-first + cache fallback.
  Future<List<ClassEntity>> getMyClasses() async {
    if (_serverReachabilityService.isServerReachable) {
      try {
        final result = await _remoteDataSource.getMyClasses();
        // Fire-and-forget cache update
        unawaited(_localDataSource.cacheClasses(result));
        return result;
      } on NetworkException catch (_) {
        // Flaky connection - fall through to cache
      } catch (e) {
        // ServerException or other errors bubble up
        rethrow;
      }
    }

    // Offline or network failure - use cached data
    return await _localDataSource.getCachedClasses();
  }

  /// Fetches class detail with online-first + cache fallback.
  Future<ClassDetail> getClassDetail(String classId) async {
    if (_serverReachabilityService.isServerReachable) {
      try {
        final result = await _remoteDataSource.getClassDetail(classId: classId);
        // Fire-and-forget cache update
        unawaited(_localDataSource.cacheClassDetail(result));
        return result;
      } on NetworkException catch (_) {
        // Flaky connection - fall through to cache
      } catch (e) {
        // ServerException or other errors bubble up
        rethrow;
      }
    }

    // Offline or network failure - use cached data
    return await _localDataSource.getCachedClassDetail(classId);
  }
}
