import 'package:likha/core/utils/typedef.dart';
import 'package:likha/domain/assessments/entities/submission.dart';
import 'package:likha/domain/assessments/repositories/assessment_repository.dart';

class GetSubmissionDetail {
  final AssessmentRepository _repository;

  GetSubmissionDetail(this._repository);

  ResultFuture<SubmissionDetail?> call(String submissionId, {bool skipBackgroundRefresh = false}) {
    return _repository.getSubmissionDetail(submissionId: submissionId, skipBackgroundRefresh: skipBackgroundRefresh);
  }
}
