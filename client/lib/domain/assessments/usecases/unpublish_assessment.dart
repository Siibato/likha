import 'package:likha/core/sync/mutation_result.dart';
import 'package:likha/core/utils/typedef.dart';
import 'package:likha/domain/assessments/entities/assessment.dart';
import 'package:likha/domain/assessments/repositories/assessment_repository.dart';

class UnpublishAssessment {
  final AssessmentRepository _repository;

  UnpublishAssessment(this._repository);

  ResultFuture<MutationResult<Assessment>> call(String assessmentId) {
    return _repository.unpublishAssessment(assessmentId: assessmentId);
  }
}
