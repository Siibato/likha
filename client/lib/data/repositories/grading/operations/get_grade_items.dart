import 'package:dartz/dartz.dart';
import 'package:likha/core/errors/exceptions.dart';
import 'package:likha/core/errors/failures.dart';
import 'package:likha/core/events/data_event_bus.dart';
import 'package:likha/core/logging/repo_logger.dart';
import 'package:likha/core/utils/remote_fetch.dart';
import 'package:likha/core/utils/typedef.dart';
import 'package:likha/data/datasources/local/grading/grading_local_datasource.dart';
import 'package:likha/data/datasources/remote/grading/grading_remote_datasource.dart';
import 'package:likha/domain/grading/entities/grade_item.dart';

import '_helpers.dart' as helpers;

ResultFuture<List<GradeItem>> getGradeItems(
  GradingLocalDataSource localDataSource,
  GradingRemoteDataSource remoteDataSource,
  DataEventBus dataEventBus, {
  required String classId,
  required int gradingPeriodNumber,
  String? component,
  bool skipBackgroundRefresh = false,
}) async {
  RepoLogger.instance.log('getGradeItems() - classId: $classId, quarter: $gradingPeriodNumber, component: $component');
  try {
    try {
      final cachedModels = await localDataSource.getItemsByClassQuarter(
        classId,
        gradingPeriodNumber,
        component: component,
      );

      // Treat empty list as cache miss
      if (cachedModels.isEmpty) {
        throw CacheException('No cached grade items found');
      }

      final entities = cachedModels.map(helpers.itemToEntity).toList();

      if (!skipBackgroundRefresh) {
        fireRemoteFetch(
          dedupKey: 'grading/items/$classId/$gradingPeriodNumber/${component ?? 'all'}/bg',
          remote: () => remoteDataSource.getGradeItems(
            classId: classId,
            gradingPeriodNumber: gradingPeriodNumber,
            component: component,
          ),
          onSuccess: (freshModels) async {
            final List<GradeItem> current;
            try {
              final currentModels = await localDataSource.getItemsByClassQuarter(
                classId,
                gradingPeriodNumber,
                component: component,
              );
              current = currentModels.map(helpers.itemToEntity).toList();
            } on CacheException {
              await localDataSource.saveItems(freshModels);
              dataEventBus.notifyGradeItemsChanged(classId);
              return;
            }
            final fresh = freshModels.map(helpers.itemToEntity).toList();
            if (helpers.gradeItemsHaveChanged(current, fresh)) {
              await localDataSource.saveItems(freshModels);
              dataEventBus.notifyGradeItemsChanged(classId);
            }
          },
        );
      }

      return Right(entities);
    } on CacheException {
      final freshModels = await remoteFetch(
        dedupKey: 'grading/items/$classId/$gradingPeriodNumber/${component ?? 'all'}',
        remote: () => remoteDataSource.getGradeItems(
          classId: classId,
          gradingPeriodNumber: gradingPeriodNumber,
          component: component,
        ),
      );
      await localDataSource.saveItems(freshModels);
      final entities = freshModels.map(helpers.itemToEntity).toList();
      return Right(entities);
    }
  } on ServerException catch (e) {
    return Left(ServerFailure(e.message));
  } on NetworkException catch (e) {
    return Left(NetworkFailure(e.message));
  } on CacheException catch (e) {
    return Left(CacheFailure(e.message));
  } catch (e) {
    RepoLogger.instance.error('getGradeItems() - unexpected error', e);
    return Left(ServerFailure(e.toString()));
  }
}
