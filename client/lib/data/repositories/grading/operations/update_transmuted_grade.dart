import 'package:dartz/dartz.dart';
import 'package:likha/core/errors/failures.dart';
import 'package:likha/core/utils/typedef.dart';
import 'package:likha/data/datasources/local/grading/grading_local_datasource.dart';

ResultVoid updateTransmutedGrade(
  GradingLocalDataSource localDataSource, {
  required String classId,
  required String studentId,
  required int gradingPeriodNumber,
  required int transmutedGrade,
}) async {
  try {
    await localDataSource.updateTransmutedGrade(
      classId,
      studentId,
      gradingPeriodNumber,
      transmutedGrade,
    );
    return const Right(null);
  } catch (e) {
    return Left(CacheFailure(e.toString()));
  }
}
