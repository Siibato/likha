import 'package:dartz/dartz.dart';
import 'package:likha/core/errors/exceptions.dart';
import 'package:likha/core/errors/failures.dart';
import 'package:likha/core/utils/remote_fetch.dart';
import 'package:likha/core/utils/typedef.dart';
import 'package:likha/data/datasources/local/assessments/assessment_local_datasource.dart';
import 'package:likha/data/datasources/remote/assessments/assessment_remote_datasource.dart';
import 'package:likha/domain/assessments/entities/submission.dart';

bool _submissionsHaveChanged(SubmissionSummary? current, SubmissionSummary? fresh) {
  if (current == null && fresh == null) return false;
  if (current == null || fresh == null) return true;
  if (current.id != fresh.id) return true;
  if (current.isSubmitted != fresh.isSubmitted) return true;
  if (current.autoScore != fresh.autoScore) return true;
  if (current.finalScore != fresh.finalScore) return true;
  if (current.submittedAt != fresh.submittedAt) return true;
  return false;
}

ResultFuture<SubmissionSummary?> getStudentSubmission(
  AssessmentLocalDataSource localDataSource,
  AssessmentRemoteDataSource remoteDataSource, {
  required String assessmentId,
  required String studentId,
}) async {
  try {
    try {
      final cached = await localDataSource.getCachedStudentSubmission(
        assessmentId,
        studentId,
      );

      fireRemoteFetch(
        dedupKey: 'assessments/studentSubmission/$assessmentId/$studentId/bg',
        remote: () => remoteDataSource.getStudentSubmission(
          assessmentId: assessmentId,
          studentId: studentId,
        ),
        onSuccess: (fresh) async {
          if (_submissionsHaveChanged(cached, fresh)) {
            await localDataSource.cacheStudentSubmission(
              assessmentId,
              studentId,
              fresh,
            );
          }
        },
      );
      return Right(cached);
    } on CacheException {
      final fresh = await remoteFetch(
        dedupKey: 'assessments/studentSubmission/$assessmentId/$studentId',
        remote: () => remoteDataSource.getStudentSubmission(
          assessmentId: assessmentId,
          studentId: studentId,
        ),
      );
      await localDataSource.cacheStudentSubmission(
        assessmentId,
        studentId,
        fresh,
      );
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
