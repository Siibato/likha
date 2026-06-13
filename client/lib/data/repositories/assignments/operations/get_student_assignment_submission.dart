import 'package:dartz/dartz.dart';
import 'package:likha/core/errors/failures.dart';
import 'package:likha/core/utils/typedef.dart';
import 'package:likha/domain/assignments/entities/assignment_submission.dart';
import 'package:likha/data/datasources/local/assignments/assignment_local_datasource.dart';
import 'package:likha/data/datasources/remote/assignments/assignment_remote_datasource.dart';

ResultFuture<StudentAssignmentStatus?> getStudentAssignmentSubmission(
  AssignmentLocalDataSource localDataSource,
  AssignmentRemoteDataSource remoteDataSource, {
  required String assignmentId,
  required String studentId,
}) async {
  try {
    final record = await localDataSource
        .getStudentSubmissionForAssignment(assignmentId, studentId);
    if (record == null) return const Right(null);
    return Right(StudentAssignmentStatus(
      submissionId: record.$1,
      status: record.$2,
      score: record.$3,
    ));
  } catch (e) {
    return Left(CacheFailure(e.toString()));
  }
}
