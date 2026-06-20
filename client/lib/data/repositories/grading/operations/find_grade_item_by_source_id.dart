import 'package:dartz/dartz.dart';
import 'package:likha/core/errors/failures.dart';
import 'package:likha/core/utils/typedef.dart';
import 'package:likha/data/datasources/local/grading/grading_local_datasource.dart';
import 'package:likha/domain/grading/entities/grade_item.dart';

import '_helpers.dart' as helpers;

ResultFuture<GradeItem?> findGradeItemBySourceId(
  GradingLocalDataSource localDataSource, {
  required String sourceId,
}) async {
  try {
    final model = await localDataSource.getItemBySourceId(sourceId);
    return Right(model != null ? helpers.itemToEntity(model) : null);
  } catch (e) {
    return Left(CacheFailure(e.toString()));
  }
}
