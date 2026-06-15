import 'package:likha/core/utils/typedef.dart';
import 'package:likha/domain/assignments/entities/assignment_submission.dart';
import 'package:likha/domain/assignments/repositories/assignment_repository.dart';

class GradeSubmission {
  final AssignmentRepository _repository;

  GradeSubmission(this._repository);

  ResultFuture<AssignmentSubmission> call(GradeSubmissionParams params) {
    return _repository.gradeSubmission(
      submissionId: params.submissionId,
      score: params.score,
      feedback: params.feedback,
    );
  }
}

class GradeSubmissionParams {
  final String submissionId;
  final int score;
  final String? feedback;

  GradeSubmissionParams({
    required this.submissionId,
    required this.score,
    this.feedback,
  });
}
