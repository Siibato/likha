import 'package:dartz/dartz.dart';
import 'package:likha/core/errors/failures.dart';
import 'package:likha/core/network/server_reachability_service.dart';
import 'package:likha/core/utils/typedef.dart';
import 'package:likha/data/datasources/local/grading/grading_local_datasource.dart';
import 'package:likha/data/datasources/remote/grading/grading_remote_datasource.dart';
import 'package:likha/domain/grading/entities/period_grade.dart';

import '_helpers.dart' as helpers;

ResultFuture<List<PeriodGrade>> getMyGrades(
  ServerReachabilityService serverReachabilityService,
  GradingLocalDataSource localDataSource,
  GradingRemoteDataSource remoteDataSource, {
  required String classId,
}) async {
  try {
    if (serverReachabilityService.isServerReachable) {
      final models = await remoteDataSource.getMyGrades(classId: classId);
      await localDataSource.savePeriodGrades(models);
      return Right(models.map(helpers.periodToEntity).toList());
    }
    return const Right([]);
  } on ServerFailure catch (e) {
    return Left(e);
  } on Failure catch (e) {
    return Left(e);
  } catch (e) {
    return Left(ServerFailure(e.toString()));
  }
}
