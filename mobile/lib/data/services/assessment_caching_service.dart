import 'dart:async';

import 'package:likha/core/errors/exceptions.dart';
import 'package:likha/core/network/connectivity_service.dart';
import 'package:likha/core/network/server_reachability_service.dart';
import 'package:likha/data/datasources/local/assessments/assessment_local_datasource.dart';
import 'package:likha/data/datasources/remote/assessment_remote_datasource.dart';
import 'package:likha/domain/assessments/entities/assessment.dart';
import 'package:likha/domain/assessments/entities/question.dart';

/// Domain-specific caching service for assessments.
///
/// Handles the special case where assessment detail returns a tuple
/// (Assessment, List<Question>) but caching requires splitting these.
class AssessmentCachingService {
  final AssessmentRemoteDataSource _remoteDataSource;
  final AssessmentLocalDataSource _localDataSource;
  final ServerReachabilityService _serverReachabilityService;

  AssessmentCachingService(
    this._remoteDataSource,
    this._localDataSource,
    this._serverReachabilityService,
  );

  /// Fetches assessments with online-first + cache fallback.
  Future<List<Assessment>> getAssessments(String classId) async {
    if (_serverReachabilityService.isServerReachable) {
      try {
        final result = await _remoteDataSource.getAssessments(classId: classId);
        // Fire-and-forget cache update
        unawaited(_localDataSource.cacheAssessments(result));
        return result;
      } on NetworkException catch (_) {
        // Flaky connection - fall through to cache
      } catch (e) {
        // ServerException or other errors bubble up
        rethrow;
      }
    }

    // Offline or network failure - use cached data
    return await _localDataSource.getCachedAssessments(classId);
  }

  /// Fetches assessment detail with online-first + cache fallback.
  ///
  /// Special handling: splits the detail into assessment + questions
  /// for caching, then reconstructs the tuple for return.
  Future<(Assessment, List<Question>)> getAssessmentDetail(
    String assessmentId,
  ) async {
    if (_serverReachabilityService.isServerReachable) {
      try {
        final result = await _remoteDataSource.getAssessmentDetail(
          assessmentId: assessmentId,
        );
        // Fire-and-forget cache update - split tuple for storage
        unawaited(_localDataSource.cacheAssessmentDetail(
          result.assessment,
          result.questions,
        ));
        return (result.assessment, result.questions);
      } on NetworkException catch (_) {
        // Flaky connection - fall through to cache
      } catch (e) {
        // ServerException or other errors bubble up
        rethrow;
      }
    }

    // Offline or network failure - use cached data
    return await _localDataSource.getCachedAssessmentDetail(assessmentId);
  }
}
