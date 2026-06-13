import 'package:dartz/dartz.dart';
import 'package:likha/core/errors/failures.dart';
import 'package:likha/core/logging/repo_logger.dart';
import 'package:likha/core/network/server_reachability_service.dart';
import 'package:likha/core/utils/typedef.dart';
import 'package:likha/data/datasources/local/grading/grading_local_datasource.dart';
import 'package:likha/data/datasources/remote/grading/grading_remote_datasource.dart';
import 'package:likha/domain/grading/entities/grade_item.dart';

import '_helpers.dart' as helpers;

ResultFuture<List<GradeItem>> getGradeItems(
  ServerReachabilityService serverReachabilityService,
  GradingLocalDataSource localDataSource,
  GradingRemoteDataSource remoteDataSource, {
  required String classId,
  required int gradingPeriodNumber,
  String? component,
}) async {
  RepoLogger.instance.log('getGradeItems() - classId: $classId, quarter: $gradingPeriodNumber, component: $component');
  try {
    
    if (serverReachabilityService.isServerReachable) {
      RepoLogger.instance.log('getGradeItems() - fetching from remote datasource');
      try {
        final models = await remoteDataSource.getGradeItems(
          classId: classId,
          gradingPeriodNumber: gradingPeriodNumber,
          component: component,
        );
        await localDataSource.saveItems(models);
        final entities = models.map(helpers.itemToEntity).toList();
        return Right(entities);
      } catch (e) {
        RepoLogger.instance.error('getGradeItems() - Error during remote fetch', e);
        rethrow;
      }
    }
    
    RepoLogger.instance.log('getGradeItems() - server not reachable, using cache');
    final cached = await localDataSource.getItemsByClassQuarter(
      classId,
      gradingPeriodNumber,
      component: component,
    );
    final entities = cached.map(helpers.itemToEntity).toList();
    return Right(entities);
  } on ServerFailure catch (e) {
    return Left(e);
  } catch (e) {
    RepoLogger.instance.error('getGradeItems() - Exception, trying cache fallback', e);
    try {
      final cached = await localDataSource.getItemsByClassQuarter(
        classId,
        gradingPeriodNumber,
        component: component,
      );
      final entities = cached.map(helpers.itemToEntity).toList();
      return Right(entities);
    } catch (_) {
      return Left(CacheFailure(e.toString()));
    }
  }
}
