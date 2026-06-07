import 'package:likha/core/utils/typedef.dart';
import 'package:likha/domain/grading/repositories/grading_repository.dart';

class ComputeGrades {
  final GradingRepository _repository;

  ComputeGrades(this._repository);

  ResultVoid call({required String classId, required int gradingPeriodNumber}) {
    return _repository.computeGrades(classId: classId, gradingPeriodNumber: gradingPeriodNumber);
  }
}
