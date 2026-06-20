import 'package:dartz/dartz.dart';
import 'package:likha/core/errors/failures.dart';
import 'package:likha/core/utils/typedef.dart';
import 'package:likha/data/datasources/remote/grading/grading_remote_datasource.dart';

ResultVoid computeGrades(
  GradingRemoteDataSource remoteDataSource, {
  required String classId,
  required int gradingPeriodNumber,
}) async {
  try {
    await remoteDataSource.computeGrades(
      classId: classId,
      gradingPeriodNumber: gradingPeriodNumber,
    );
    return const Right(null);
  } on ServerFailure catch (e) {
    return Left(e);
  } catch (e) {
    return Left(CacheFailure(e.toString()));
  }
}
