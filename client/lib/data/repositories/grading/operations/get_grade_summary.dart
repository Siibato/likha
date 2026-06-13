import 'package:dartz/dartz.dart';
import 'package:likha/core/errors/failures.dart';
import 'package:likha/core/utils/typedef.dart';
import 'package:likha/data/datasources/remote/grading/grading_remote_datasource.dart';

ResultFuture<List<Map<String, dynamic>>> getGradeSummary(
  GradingRemoteDataSource remoteDataSource, {
  required String classId,
  required int gradingPeriodNumber,
}) async {
  try {
    final summary = await remoteDataSource.getGradeSummary(
      classId: classId,
      gradingPeriodNumber: gradingPeriodNumber,
    );
    return Right(summary);
  } on ServerFailure catch (e) {
    // Propagate server errors (e.g. 400 "Grading config not set up") so the
    // UI can show a "syncing to server" banner instead of blank grades.
    return Left(e);
  } on Failure {
    return const Right([]);
  } catch (_) {
    return const Right([]);
  }
}
