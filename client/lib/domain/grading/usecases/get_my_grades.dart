import 'package:likha/core/utils/typedef.dart';
import 'package:likha/domain/grading/entities/term_grade.dart';
import 'package:likha/domain/grading/repositories/grading_repository.dart';

class GetMyGrades {
  final GradingRepository _repository;

  GetMyGrades(this._repository);

  ResultFuture<List<TermGrade>> call(String classId) {
    return _repository.getMyGrades(classId: classId);
  }
}
