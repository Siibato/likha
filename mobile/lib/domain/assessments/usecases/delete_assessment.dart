import 'package:likha/core/utils/typedef.dart';
import 'package:likha/domain/assessments/repositories/assessment_repository.dart';

class DeleteAssessment {
  final AssessmentRepository _repository;

  DeleteAssessment(this._repository);

  ResultVoid call(String assessmentId) {
    return _repository.deleteAssessment(assessmentId: assessmentId);
  }
}
