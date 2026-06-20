import 'package:dartz/dartz.dart';
import 'package:likha/core/errors/exceptions.dart';
import 'package:likha/core/errors/failures.dart';
import 'package:likha/core/events/data_event_bus.dart';
import 'package:likha/core/utils/remote_fetch.dart';
import 'package:likha/core/utils/typedef.dart';
import 'package:likha/domain/assessments/entities/submission.dart';
import 'package:likha/data/datasources/local/assessments/assessment_local_datasource.dart';
import 'package:likha/data/datasources/remote/assessments/assessment_remote_datasource.dart';

ResultFuture<SubmissionDetail?> getSubmissionDetail(
  AssessmentLocalDataSource localDataSource,
  AssessmentRemoteDataSource remoteDataSource,
  DataEventBus dataEventBus, {
  required String submissionId,
  bool skipBackgroundRefresh = false,
}) async {
  try {
    final cached = await localDataSource.getCachedSubmissionDetail(submissionId);

    if (cached != null) {
      if (!skipBackgroundRefresh) {
        fireRemoteFetch(
          dedupKey: 'assessments/submission/$submissionId/bg',
          remote: () => remoteDataSource.getSubmissionDetail(submissionId: submissionId),
          onSuccess: (fresh) async {
            try {
              final current = await localDataSource.getCachedSubmissionDetail(submissionId);
              if (current == null ||
                  current.answers.length != fresh.answers.length ||
                  current.totalPoints != fresh.totalPoints ||
                  current.finalScore != fresh.finalScore) {
                await localDataSource.cacheSubmissionDetail(fresh);
                dataEventBus.notifySubmissionDetailChanged(submissionId);
              }
            } catch (_) {
              await localDataSource.cacheSubmissionDetail(fresh);
              dataEventBus.notifySubmissionDetailChanged(submissionId);
            }
          },
        );
      }

      return Right(cached);
    }

    // Cache miss: fire non-blocking background fetch, return null immediately
    if (!skipBackgroundRefresh) {
      fireRemoteFetch(
        dedupKey: 'assessments/submission/$submissionId/bg',
        remote: () => remoteDataSource.getSubmissionDetail(submissionId: submissionId),
        onSuccess: (fresh) async {
          await localDataSource.cacheSubmissionDetail(fresh);
          dataEventBus.notifySubmissionDetailChanged(submissionId);
        },
        onError: (_) {
          dataEventBus.notifySubmissionDetailChanged(submissionId);
        },
      );
    }

    return const Right(null);
  } on ServerException catch (e) {
    return Left(ServerFailure(e.message, statusCode: e.statusCode));
  } on NetworkException catch (e) {
    return Left(NetworkFailure(e.message));
  } catch (e) {
    return Left(ServerFailure(e.toString()));
  }
}
