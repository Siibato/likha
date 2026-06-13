import 'package:dartz/dartz.dart';
import 'package:likha/core/errors/failures.dart';
import 'package:likha/core/network/server_reachability_service.dart';
import 'package:likha/core/utils/typedef.dart';
import 'package:likha/data/datasources/local/grading/grading_local_datasource.dart';
import 'package:likha/data/datasources/remote/grading/grading_remote_datasource.dart';
import 'package:likha/domain/grading/entities/period_grade.dart';

import '_helpers.dart' as helpers;

ResultFuture<List<PeriodGrade>> getPeriodGrades(
  ServerReachabilityService serverReachabilityService,
  GradingLocalDataSource localDataSource,
  GradingRemoteDataSource remoteDataSource, {
  required String classId,
  required int gradingPeriodNumber,
}) async {
  try {
    if (serverReachabilityService.isServerReachable) {
      final models = await remoteDataSource.getPeriodGrades(
        classId: classId,
        gradingPeriodNumber: gradingPeriodNumber,
      );
      await localDataSource.savePeriodGrades(models);
      return Right(models.map(helpers.periodToEntity).toList());
    }
    final cached = await localDataSource.getPeriodGradesByClass(
      classId,
      gradingPeriodNumber,
    );
    return Right(cached.map(helpers.periodToEntity).toList());
  } on ServerFailure catch (e) {
    return Left(e);
  } on Failure catch (e) {
    return Left(e);
  } catch (e) {
    try {
      final cached = await localDataSource.getPeriodGradesByClass(
        classId,
        gradingPeriodNumber,
      );
      return Right(cached.map(helpers.periodToEntity).toList());
    } catch (_) {
      return Left(CacheFailure(e.toString()));
    }
  }
}
