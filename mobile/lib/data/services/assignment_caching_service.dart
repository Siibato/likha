import 'dart:async';

import 'package:likha/core/errors/exceptions.dart';
import 'package:likha/core/network/server_reachability_service.dart';
import 'package:likha/data/datasources/local/assignment_local_datasource.dart';
import 'package:likha/data/datasources/remote/assignment_remote_datasource.dart';
import 'package:likha/domain/assignments/entities/assignment.dart';

/// Domain-specific caching service for assignments.
class AssignmentCachingService {
  final AssignmentRemoteDataSource _remoteDataSource;
  final AssignmentLocalDataSource _localDataSource;
  final ServerReachabilityService _serverReachabilityService;

  AssignmentCachingService(
    this._remoteDataSource,
    this._localDataSource,
    this._serverReachabilityService,
  );

  /// Fetches assignments for a class with online-first + cache fallback.
  Future<List<Assignment>> getAssignments(String classId) async {
    if (_serverReachabilityService.isServerReachable) {
      try {
        final result =
            await _remoteDataSource.getAssignments(classId: classId);
        // Fire-and-forget cache update
        unawaited(_localDataSource.cacheAssignments(result));
        return result;
      } on NetworkException catch (_) {
        // Flaky connection - fall through to cache
      } catch (e) {
        // ServerException or other errors bubble up
        rethrow;
      }
    }

    // Offline or network failure - use cached data
    return await _localDataSource.getCachedAssignments(classId);
  }

  /// Fetches assignment detail with online-first + cache fallback.
  Future<Assignment> getAssignmentDetail(String assignmentId) async {
    if (_serverReachabilityService.isServerReachable) {
      try {
        final result = await _remoteDataSource.getAssignmentDetail(
          assignmentId: assignmentId,
        );
        // Fire-and-forget cache update
        unawaited(_localDataSource.cacheAssignmentDetail(result));
        return result;
      } on NetworkException catch (_) {
        // Flaky connection - fall through to cache
      } catch (e) {
        // ServerException or other errors bubble up
        rethrow;
      }
    }

    // Offline or network failure - use cached data
    return await _localDataSource.getCachedAssignmentDetail(assignmentId);
  }
}
