import 'package:dartz/dartz.dart';
import 'package:likha/core/logging/repo_logger.dart';
import 'package:likha/core/errors/exceptions.dart';
import 'package:likha/core/errors/failures.dart';
import 'package:likha/core/utils/remote_fetch.dart';
import 'package:likha/core/utils/typedef.dart';
import 'package:likha/domain/assessments/entities/assessment.dart';
import 'package:likha/data/datasources/local/assessments/assessment_local_datasource.dart';
import 'package:likha/data/datasources/remote/assessments/assessment_remote_datasource.dart';
import 'package:likha/core/events/data_event_bus.dart';

ResultFuture<List<Assessment>> getAssessments(
  AssessmentLocalDataSource localDataSource,
  AssessmentRemoteDataSource remoteDataSource,
  DataEventBus dataEventBus, {
  required String classId,
  bool publishedOnly = false,
  bool skipBackgroundRefresh = false,
}) async {
  try {
    try {
      RepoLogger.instance.log('getAssessments() - loading from cache for classId: $classId');
      final cachedAssessments = await localDataSource.getCachedAssessments(classId, publishedOnly: publishedOnly);
      RepoLogger.instance.log('getAssessments() - loaded ${cachedAssessments.length} cached assessments');

      if (!skipBackgroundRefresh) {
        fireRemoteFetch(
          dedupKey: 'assessments/$classId/bg',
          remote: () => remoteDataSource.getAssessments(classId: classId),
          onSuccess: (fresh) async {
            final List<Assessment> current;
            try {
              current = await localDataSource.getCachedAssessments(classId, publishedOnly: publishedOnly);
            } on CacheException {
              await localDataSource.cacheAssessments(fresh);
              dataEventBus.notifyAssessmentsChanged(classId);
              return;
            }
            if (_assessmentsHaveChanged(current, fresh)) {
              await localDataSource.cacheAssessments(fresh);
              dataEventBus.notifyAssessmentsChanged(classId);
            }
          },
        );
      }

      for (final a in cachedAssessments) {
        RepoLogger.instance.log('${a.title} | totalPoints=${a.totalPoints} | termNumber=${a.termNumber} | component=${a.component}');
      }
      return Right(cachedAssessments.cast<Assessment>());
    } on CacheException {
      final fresh = await remoteFetch(
        dedupKey: 'assessments/$classId',
        remote: () => remoteDataSource.getAssessments(classId: classId),
      );
      await localDataSource.cacheAssessments(fresh);
      return Right(fresh);
    }
  } on ServerException catch (e) {
    return Left(ServerFailure(e.message, statusCode: e.statusCode));
  } on NetworkException catch (e) {
    return Left(NetworkFailure(e.message));
  } on CacheException catch (e) {
    return Left(CacheFailure(e.message));
  } catch (e) {
    return Left(ServerFailure(e.toString()));
  }
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
    if (l.termNumber != r.termNumber) return true;
    if (l.component != r.component) return true;
  }
  return false;
}
