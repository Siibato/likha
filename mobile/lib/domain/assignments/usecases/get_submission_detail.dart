import 'package:likha/core/utils/typedef.dart';
import 'package:likha/domain/assignments/entities/assignment_submission.dart';
import 'package:likha/domain/assignments/repositories/assignment_repository.dart';

class GetAssignmentSubmissionDetail {
  final AssignmentRepository _repository;

  GetAssignmentSubmissionDetail(this._repository);

  ResultFuture<AssignmentSubmission> call(String submissionId) {
    return _repository.getSubmissionDetail(submissionId: submissionId);
  }
}
