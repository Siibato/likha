import 'package:likha/core/utils/typedef.dart';
import 'package:likha/domain/assignments/entities/assignment_submission.dart';
import 'package:likha/domain/assignments/repositories/assignment_repository.dart';

class CreateSubmission {
  final AssignmentRepository _repository;

  CreateSubmission(this._repository);

  ResultFuture<AssignmentSubmission> call(CreateSubmissionParams params) {
    return _repository.createSubmission(
      assignmentId: params.assignmentId,
      textContent: params.textContent,
    );
  }
}

class CreateSubmissionParams {
  final String assignmentId;
  final String? textContent;

  CreateSubmissionParams({
    required this.assignmentId,
    this.textContent,
  });
}
