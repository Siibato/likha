import 'package:equatable/equatable.dart';
import 'package:likha/core/utils/typedef.dart';
import 'package:likha/domain/assignments/entities/assignment_submission.dart';
import 'package:likha/domain/assignments/repositories/assignment_repository.dart';

class GetStudentAssignmentSubmission {
  final AssignmentRepository _repository;
  const GetStudentAssignmentSubmission(this._repository);

  ResultFuture<StudentAssignmentStatus?> call(GetStudentAssignmentSubmissionParams params) =>
      _repository.getStudentAssignmentSubmission(
        assignmentId: params.assignmentId,
        studentId: params.studentId,
      );
}

class GetStudentAssignmentSubmissionParams extends Equatable {
  final String assignmentId;
  final String studentId;
  const GetStudentAssignmentSubmissionParams({
    required this.assignmentId,
    required this.studentId,
  });
  @override
  List<Object> get props => [assignmentId, studentId];
}
