import 'package:likha/core/utils/typedef.dart';
import 'package:likha/domain/assessments/entities/submission.dart';
import 'package:likha/domain/assessments/repositories/assessment_repository.dart';

class GetSubmissions {
  final AssessmentRepository _repository;

  GetSubmissions(this._repository);

  ResultFuture<List<SubmissionSummary>> call(String assessmentId) {
    return _repository.getSubmissions(assessmentId: assessmentId);
  }
}
