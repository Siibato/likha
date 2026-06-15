import 'package:likha/core/utils/typedef.dart';
import 'package:likha/domain/grading/entities/period_grade.dart';
import 'package:likha/domain/grading/repositories/grading_repository.dart';

class GetPeriodGrades {
  final GradingRepository _repository;

  GetPeriodGrades(this._repository);

  ResultFuture<List<PeriodGrade>> call({
    required String classId,
    required int gradingPeriodNumber,
  }) {
    return _repository.getPeriodGrades(classId: classId, gradingPeriodNumber: gradingPeriodNumber);
  }
}
