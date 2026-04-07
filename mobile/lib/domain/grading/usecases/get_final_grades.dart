import 'package:likha/core/utils/typedef.dart';
import 'package:likha/domain/grading/repositories/grading_repository.dart';

class GetFinalGrades {
  final GradingRepository _repository;

  GetFinalGrades(this._repository);

  ResultFuture<List<Map<String, dynamic>>> call(String classId) {
    return _repository.getFinalGrades(classId: classId);
  }
}
