import 'package:likha/core/utils/typedef.dart';
import 'package:likha/domain/assessments/entities/submission.dart';
import 'package:likha/domain/assessments/repositories/assessment_repository.dart';

class StartAssessment {
  final AssessmentRepository _repository;

  StartAssessment(this._repository);

  ResultFuture<StartSubmissionResult> call(StartAssessmentParams params) {
    return _repository.startAssessment(
      assessmentId:    params.assessmentId,
      studentId:       params.studentId,
      studentName:     params.studentName,
      studentUsername: params.studentUsername,
    );
  }
}

class StartAssessmentParams {
  final String assessmentId;
  final String studentId;
  final String studentName;
  final String studentUsername;

  StartAssessmentParams({
    required this.assessmentId,
    required this.studentId,
    required this.studentName,
    required this.studentUsername,
  });
}
