import 'package:likha/core/utils/typedef.dart';
import 'package:likha/domain/grading/repositories/grading_repository.dart';

class GetMyGradeDetail {
  final GradingRepository _repository;

  GetMyGradeDetail(this._repository);

  ResultFuture<Map<String, dynamic>> call({
    required String classId,
    required int gradingPeriodNumber,
  }) {
    return _repository.getMyGradeDetail(classId: classId, gradingPeriodNumber: gradingPeriodNumber);
  }
}
