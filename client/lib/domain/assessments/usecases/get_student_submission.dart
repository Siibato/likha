import 'package:equatable/equatable.dart';
import 'package:likha/core/utils/typedef.dart';
import 'package:likha/domain/assessments/entities/submission.dart';
import 'package:likha/domain/assessments/repositories/assessment_repository.dart';

class GetStudentSubmission {
  final AssessmentRepository _repository;
  const GetStudentSubmission(this._repository);

  ResultFuture<SubmissionSummary?> call(GetStudentSubmissionParams params) =>
      _repository.getStudentSubmission(
        assessmentId: params.assessmentId,
        studentId: params.studentId,
      );
}

class GetStudentSubmissionParams extends Equatable {
  final String assessmentId;
  final String studentId;
  const GetStudentSubmissionParams({
    required this.assessmentId,
    required this.studentId,
  });
  @override
  List<Object> get props => [assessmentId, studentId];
}
