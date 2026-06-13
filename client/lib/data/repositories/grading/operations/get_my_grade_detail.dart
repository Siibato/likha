import 'package:dartz/dartz.dart';
import 'package:likha/core/errors/failures.dart';
import 'package:likha/core/utils/typedef.dart';
import 'package:likha/data/datasources/remote/grading/grading_remote_datasource.dart';

ResultFuture<Map<String, dynamic>> getMyGradeDetail(
  GradingRemoteDataSource remoteDataSource, {
  required String classId,
  required int gradingPeriodNumber,
}) async {
  try {
    final detail = await remoteDataSource.getMyGradeDetail(
      classId: classId,
      gradingPeriodNumber: gradingPeriodNumber,
    );
    return Right(detail);
  } on ServerFailure catch (e) {
    return Left(e);
  } on Failure catch (e) {
    return Left(e);
  } catch (e) {
    return Left(ServerFailure(e.toString()));
  }
}
