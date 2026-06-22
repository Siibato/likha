import 'package:likha/core/utils/typedef.dart';
import 'package:likha/domain/grading/entities/term_grade.dart';
import 'package:likha/domain/grading/repositories/grading_repository.dart';

class GetTermGrades {
  final GradingRepository _repository;

  GetTermGrades(this._repository);

  ResultFuture<List<TermGrade>> call({
    required String classId,
    required int termNumber,
  }) {
    return _repository.getTermGrades(classId: classId, termNumber: termNumber);
  }
}
