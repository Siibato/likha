import 'package:dartz/dartz.dart';
import 'package:likha/core/logging/repo_logger.dart';
import 'package:likha/core/errors/exceptions.dart';
import 'package:likha/core/errors/failures.dart';
import 'package:likha/core/utils/typedef.dart';
import 'package:likha/domain/assessments/entities/assessment.dart';
import 'package:likha/core/network/server_reachability_service.dart';
import 'package:likha/data/datasources/local/assessments/assessment_local_datasource.dart';
import 'package:likha/data/datasources/remote/assessments/assessment_remote_datasource.dart';
import 'package:likha/services/storage_service.dart';
import 'package:likha/core/events/data_event_bus.dart';

ResultFuture<List<Assessment>> getAssessments(
  ServerReachabilityService serverReachabilityService,
AssessmentLocalDataSource localDataSource,
AssessmentRemoteDataSource remoteDataSource,
StorageService storageService,
DataEventBus dataEventBus, {
  required String classId,
  bool publishedOnly = false,
  bool skipBackgroundRefresh = false,
  bool forceRemote = false,
}) async {
  if (forceRemote && serverReachabilityService.isServerReachable) {
    try {
      RepoLogger.instance.log('getAssessments() - forceRemote=true, fetching from remote for classId: $classId');
      final fresh = await remoteDataSource.getAssessments(classId: classId);
      await localDataSource.cacheAssessments(fresh);
      RepoLogger.instance.log('getAssessments() - forceRemote: got ${fresh.length} assessments');
      return Right(fresh);
    } catch (e) {
      RepoLogger.instance.warn('getAssessments() - forceRemote fetch failed, falling through to cache', e);
    }
  }

  try {
    try {
      RepoLogger.instance.log('getAssessments() - loading from cache for classId: $classId');
      final cachedAssessments = await localDataSource.getCachedAssessments(classId, publishedOnly: publishedOnly);
      RepoLogger.instance.log('getAssessments() - loaded ${cachedAssessments.length} cached assessments');

      String? currentStudentId;
      try {
        currentStudentId = await storageService.getUserId();
        RepoLogger.instance.log('getAssessments() - got currentStudentId: $currentStudentId');
      } catch (e) {
        RepoLogger.instance.warn('Could not get current student ID', e);
      }

      RepoLogger.instance.log('getAssessments() - computing dynamic submission counts and isSubmitted flags');
      final assessmentsWithDynamicCounts = <Assessment>[];
      for (final assessment in cachedAssessments) {
        try {
          final actualSubmissionCount = await localDataSource.getCachedSubmissionCount(assessment.id);
          bool? isSubmitted;

          if (currentStudentId != null) {
            try {
              isSubmitted = await localDataSource.hasStudentSubmittedAssessment(
                assessment.id,
                currentStudentId,
              );
            } catch (e) {
              RepoLogger.instance.warn('Error getting submission status for ${assessment.title}', e);
            }
          }

          RepoLogger.instance.log('${assessment.title}: cached=${assessment.submissionCount}, actual=$actualSubmissionCount, isSubmitted=$isSubmitted');
          if (actualSubmissionCount != assessment.submissionCount || isSubmitted != null) {
            assessmentsWithDynamicCounts.add(Assessment(
              id: assessment.id,
              classId: assessment.classId,
              title: assessment.title,
              description: assessment.description,
              timeLimitMinutes: assessment.timeLimitMinutes,
              openAt: assessment.openAt,
              closeAt: assessment.closeAt,
              showResultsImmediately: assessment.showResultsImmediately,
              resultsReleased: assessment.resultsReleased,
              isPublished: assessment.isPublished,
              orderIndex: assessment.orderIndex,
              totalPoints: assessment.totalPoints,
              questionCount: assessment.questionCount,
              submissionCount: actualSubmissionCount > 0 ? actualSubmissionCount : assessment.submissionCount,
              isSubmitted: isSubmitted,
              tosId: assessment.tosId,
              gradingPeriodNumber: assessment.gradingPeriodNumber,
              component: assessment.component,
              createdAt: assessment.createdAt,
              updatedAt: assessment.updatedAt,
              cachedAt: assessment.cachedAt,
              needsSync: assessment.needsSync,
            ));
          } else {
            assessmentsWithDynamicCounts.add(assessment);
          }
        } catch (e) {
          RepoLogger.instance.warn('Error getting submission count/status for ${assessment.title}, using cached', e);
          assessmentsWithDynamicCounts.add(assessment);
        }
      }

      if (!skipBackgroundRefresh) {
        _backgroundFetchAssessments(serverReachabilityService, localDataSource, remoteDataSource, storageService, dataEventBus, classId, publishedOnly: publishedOnly);
      }

      for (final a in assessmentsWithDynamicCounts) {
        RepoLogger.instance.log('${a.title} | totalPoints=${a.totalPoints} | gradingPeriod=${a.gradingPeriodNumber} | component=${a.component}');
      }
      return Right(assessmentsWithDynamicCounts);
    } on CacheException {
      if (!skipBackgroundRefresh) {
        _backgroundFetchAssessments(serverReachabilityService, localDataSource, remoteDataSource, storageService, dataEventBus, classId, publishedOnly: publishedOnly);
      }

      return const Right([]);
    }
  } catch (e) {
    return Left(ServerFailure(e.toString()));
  }
}

void _backgroundFetchAssessments(
  ServerReachabilityService serverReachabilityService,
  AssessmentLocalDataSource localDataSource,
  AssessmentRemoteDataSource remoteDataSource,
  StorageService storageService,
  DataEventBus dataEventBus,
  String classId, {
  bool publishedOnly = false,
}) {
  Future.microtask(() async {
    try {
      RepoLogger.instance.log('_backgroundFetchAssessments() - fetching fresh assessments for classId: $classId');
      final fresh =
          await remoteDataSource.getAssessments(classId: classId);
      RepoLogger.instance.log('_backgroundFetchAssessments() - received ${fresh.length} fresh assessments');

      final List<Assessment> cached;
      try {
        cached = await localDataSource.getCachedAssessments(classId, publishedOnly: publishedOnly);
        RepoLogger.instance.log('_backgroundFetchAssessments() - cached ${cached.length} assessments found');
      } on CacheException {
        RepoLogger.instance.log('_backgroundFetchAssessments() - cache miss, writing fresh data');
        await localDataSource.cacheAssessments(fresh);
        dataEventBus.notifyAssessmentsChanged(classId);
        return;
      }

      if (_assessmentsHaveChanged(cached, fresh)) {
        RepoLogger.instance.log('_backgroundFetchAssessments() - assessments changed, updating cache');
        await localDataSource.cacheAssessments(fresh);
        dataEventBus.notifyAssessmentsChanged(classId);
      } else {
        RepoLogger.instance.log('_backgroundFetchAssessments() - no changes detected, skipping cache update');
      }
    } on NetworkException {
      RepoLogger.instance.warn('_backgroundFetchAssessments() - network error, cache persists');
    } on ServerException {
      RepoLogger.instance.warn('_backgroundFetchAssessments() - server error, cache persists');
    } catch (e) {
      RepoLogger.instance.error('_backgroundFetchAssessments() - unexpected error, cache persists', e);
    }
  });
}

bool _assessmentsHaveChanged(
  List<Assessment> local,
  List<Assessment> remote,
) {
  if (local.length != remote.length) return true;
  final localById = {for (final a in local) a.id: a};
  for (final r in remote) {
    final l = localById[r.id];
    if (l == null) return true;
    if (l.updatedAt.isBefore(r.updatedAt)) return true;
    if (l.submissionCount != r.submissionCount) return true;
    if (l.gradingPeriodNumber != r.gradingPeriodNumber) return true;
    if (l.component != r.component) return true;
  }
  return false;
}
