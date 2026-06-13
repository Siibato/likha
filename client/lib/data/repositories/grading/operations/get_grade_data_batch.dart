import 'package:dartz/dartz.dart';
import 'package:likha/core/errors/failures.dart';
import 'package:likha/core/events/data_event_bus.dart';
import 'package:likha/core/utils/typedef.dart';
import 'package:likha/data/datasources/local/grading/grading_local_datasource.dart';
import 'package:likha/data/datasources/remote/grading/grading_remote_datasource.dart';
import 'package:likha/data/models/grading/grade_item_model.dart';

import 'get_grade_items.dart';
import 'get_grade_summary.dart';

ResultFuture<Map<String, dynamic>> getGradeDataBatch(
  GradingLocalDataSource localDataSource,
  GradingRemoteDataSource remoteDataSource,
  DataEventBus dataEventBus, {
  required String classId,
  required int gradingPeriodNumber,
}) async {
  try {
    // For now, implement batch loading by combining individual calls
    // This can be optimized later with a proper batch endpoint
    final gradeItemsResult = await getGradeItems(
      localDataSource,
      remoteDataSource,
      dataEventBus,
      classId: classId,
      gradingPeriodNumber: gradingPeriodNumber,
    );
    
    final gradeSummaryResult = await getGradeSummary(
      remoteDataSource,
      classId: classId,
      gradingPeriodNumber: gradingPeriodNumber,
    );
    
    return gradeItemsResult.fold(
      (failure) => Left(failure),
      (gradeItems) => gradeSummaryResult.fold(
        (failure) => Left(failure),
        (gradeSummary) => Right({
          'grade_items': gradeItems.map((item) => GradeItemModel(
            id: item.id,
            classId: item.classId,
            title: item.title,
            component: item.component,
            gradingPeriodNumber: item.gradingPeriodNumber,
            totalPoints: item.totalPoints,
            sourceType: item.sourceType,
            sourceId: item.sourceId,
            orderIndex: item.orderIndex,
            createdAt: item.createdAt,
            updatedAt: item.updatedAt,
          ).toJson()).toList(),
          'grade_summary': gradeSummary,
          'quarter': gradingPeriodNumber,
        }),
      ),
    );
  } catch (e) {
    return Left(ServerFailure(e.toString()));
  }
}
