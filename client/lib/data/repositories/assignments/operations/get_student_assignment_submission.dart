import 'package:dartz/dartz.dart';
import 'package:likha/core/errors/exceptions.dart';
import 'package:likha/core/errors/failures.dart';
import 'package:likha/core/utils/remote_fetch.dart';
import 'package:likha/core/utils/typedef.dart';
import 'package:likha/data/datasources/local/assignments/assignment_local_datasource.dart';
import 'package:likha/data/datasources/remote/assignments/assignment_remote_datasource.dart';
import 'package:likha/domain/assignments/entities/assignment_submission.dart';

bool _statusHaveChanged(StudentAssignmentStatus? current, StudentAssignmentStatus? fresh) {
  if (current == null && fresh == null) return false;
  if (current == null || fresh == null) return true;
  if (current.submissionId != fresh.submissionId) return true;
  if (current.status != fresh.status) return true;
  if (current.score != fresh.score) return true;
  return false;
}

ResultFuture<StudentAssignmentStatus?> getStudentAssignmentSubmission(
  AssignmentLocalDataSource localDataSource,
  AssignmentRemoteDataSource remoteDataSource, {
  required String assignmentId,
  required String studentId,
}) async {
  try {
    try {
      final record = await localDataSource
          .getStudentSubmissionForAssignment(assignmentId, studentId);
      final cached = record != null
          ? StudentAssignmentStatus(
              submissionId: record.$1,
              status: record.$2,
              score: record.$3,
            )
          : null;

      fireRemoteFetch(
        dedupKey: 'assignments/studentSubmission/$assignmentId/$studentId/bg',
        remote: () => remoteDataSource.getStudentAssignmentSubmission(
          assignmentId: assignmentId,
          studentId: studentId,
        ),
        onSuccess: (fresh) async {
          final freshStatus = fresh != null
              ? StudentAssignmentStatus(
                  submissionId: fresh.id,
                  status: fresh.status,
                  score: fresh.score,
                )
              : null;
          if (_statusHaveChanged(cached, freshStatus)) {
            if (fresh != null) {
              await localDataSource.cacheSubmissionDetail(fresh);
            } else {
              await localDataSource.clearStudentAssignmentSubmission(
                assignmentId,
                studentId,
              );
            }
          }
        },
      );
      return Right(cached);
    } on CacheException {
      final fresh = await remoteFetch(
        dedupKey: 'assignments/studentSubmission/$assignmentId/$studentId',
        remote: () => remoteDataSource.getStudentAssignmentSubmission(
          assignmentId: assignmentId,
          studentId: studentId,
        ),
      );
      if (fresh != null) {
        await localDataSource.cacheSubmissionDetail(fresh);
      } else {
        await localDataSource.clearStudentAssignmentSubmission(
          assignmentId,
          studentId,
        );
      }
      return Right(fresh != null
          ? StudentAssignmentStatus(
              submissionId: fresh.id,
              status: fresh.status,
              score: fresh.score,
            )
          : null);
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
