import 'package:likha/core/utils/typedef.dart';
import 'package:likha/domain/assessments/entities/submission.dart';
import 'package:likha/domain/assessments/repositories/assessment_repository.dart';

class StartAssessment {
  final AssessmentRepository _repository;

  StartAssessment(this._repository);

  ResultFuture<StartSubmissionResult> call(String assessmentId) {
    return _repository.startAssessment(assessmentId: assessmentId);
  }
}
