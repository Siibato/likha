import 'package:likha/core/utils/typedef.dart';
import 'package:likha/domain/assignments/entities/assignment_submission.dart';
import 'package:likha/domain/assignments/repositories/assignment_repository.dart';

class GetAssignmentSubmissions {
  final AssignmentRepository _repository;

  GetAssignmentSubmissions(this._repository);

  ResultFuture<List<SubmissionListItem>> call(String assignmentId) {
    return _repository.getSubmissions(assignmentId: assignmentId);
  }
}
