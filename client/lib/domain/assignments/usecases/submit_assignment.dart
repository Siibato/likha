import 'package:likha/core/sync/mutation_result.dart';
import 'package:likha/core/utils/typedef.dart';
import 'package:likha/domain/assignments/entities/assignment_submission.dart';
import 'package:likha/domain/assignments/repositories/assignment_repository.dart';

class SubmitAssignment {
  final AssignmentRepository _repository;

  SubmitAssignment(this._repository);

  ResultFuture<MutationResult<AssignmentSubmission>> call(String submissionId) {
    return _repository.submitAssignment(submissionId: submissionId);
  }
}
