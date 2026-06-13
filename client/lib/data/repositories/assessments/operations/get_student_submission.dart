import 'package:dartz/dartz.dart';
import 'package:likha/core/errors/exceptions.dart';
import 'package:likha/core/errors/failures.dart';
import 'package:likha/core/utils/typedef.dart';
import 'package:likha/domain/assessments/entities/submission.dart';
import 'package:likha/data/datasources/local/assessments/assessment_local_datasource.dart';

ResultFuture<SubmissionSummary?> getStudentSubmission(
  AssessmentLocalDataSource localDataSource, {
  required String assessmentId,
  required String studentId,
}) async {
  try {
    final result = await localDataSource.getCachedStudentSubmission(
      assessmentId,
      studentId,
    );
    return Right(result);
  } on CacheException catch (e) {
    return Left(CacheFailure(e.message));
  }
}
