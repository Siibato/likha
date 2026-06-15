import 'package:likha/core/utils/typedef.dart';
import 'package:likha/domain/assessments/entities/assessment.dart';
import 'package:likha/domain/assessments/repositories/assessment_repository.dart';

class ReleaseResults {
  final AssessmentRepository _repository;

  ReleaseResults(this._repository);

  ResultFuture<Assessment> call(String assessmentId) {
    return _repository.releaseResults(assessmentId: assessmentId);
  }
}
