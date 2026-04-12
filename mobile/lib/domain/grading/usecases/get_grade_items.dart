import 'package:likha/core/utils/typedef.dart';
import 'package:likha/domain/grading/entities/grade_item.dart';
import 'package:likha/domain/grading/repositories/grading_repository.dart';

class GetGradeItems {
  final GradingRepository _repository;

  GetGradeItems(this._repository);

  ResultFuture<List<GradeItem>> call(GetGradeItemsParams params) {
    return _repository.getGradeItems(
      classId: params.classId,
      gradingPeriodNumber: params.quarter,
      component: params.component,
    );
  }
}

class GetGradeItemsParams {
  final String classId;
  final int quarter;
  final String? component;

  GetGradeItemsParams({
    required this.classId,
    required this.quarter,
    this.component,
  });
}
