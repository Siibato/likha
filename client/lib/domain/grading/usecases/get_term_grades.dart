import 'package:likha/core/utils/typedef.dart';
import 'package:likha/domain/grading/entities/period_grade.dart';
import 'package:likha/domain/grading/repositories/grading_repository.dart';

class GetTermGrades {
  final GradingRepository _repository;

  GetTermGrades(this._repository);

  ResultFuture<List<PeriodGrade>> call({
    required String classId,
    required int termNumber,
  }) {
    return _repository.getTermGrades(classId: classId, termNumber: termNumber);
  }
}
