import 'package:likha/core/utils/typedef.dart';
import 'package:likha/domain/grading/repositories/grading_repository.dart';

class GetGradeDataBatch {
  final GradingRepository _repository;

  GetGradeDataBatch(this._repository);

  ResultFuture<Map<String, dynamic>> call({
    required String classId,
    required int gradingPeriodNumber,
  }) {
    return _repository.getGradeDataBatch(
      classId: classId,
      gradingPeriodNumber: gradingPeriodNumber,
    );
  }
}
