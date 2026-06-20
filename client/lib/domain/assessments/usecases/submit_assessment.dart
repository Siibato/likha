import 'package:likha/core/sync/mutation_result.dart';
import 'package:likha/core/utils/typedef.dart';
import 'package:likha/domain/assessments/entities/submission.dart';
import 'package:likha/domain/assessments/repositories/assessment_repository.dart';

class SubmitAssessment {
  final AssessmentRepository _repository;

  SubmitAssessment(this._repository);

  ResultFuture<MutationResult<SubmissionSummary>> call(String submissionId) {
    return _repository.submitAssessment(submissionId: submissionId);
  }
}
