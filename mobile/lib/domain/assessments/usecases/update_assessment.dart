import 'package:likha/core/utils/typedef.dart';
import 'package:likha/domain/assessments/entities/assessment.dart';
import 'package:likha/domain/assessments/repositories/assessment_repository.dart';

class UpdateAssessmentParams {
  final String assessmentId;
  final String? title;
  final String? description;
  final int? timeLimitMinutes;
  final String? openAt;
  final String? closeAt;
  final bool? showResultsImmediately;

  UpdateAssessmentParams({
    required this.assessmentId,
    this.title,
    this.description,
    this.timeLimitMinutes,
    this.openAt,
    this.closeAt,
    this.showResultsImmediately,
  });
}

class UpdateAssessment {
  final AssessmentRepository _repository;

  UpdateAssessment(this._repository);

  ResultFuture<Assessment> call(UpdateAssessmentParams params) {
    return _repository.updateAssessment(
      assessmentId: params.assessmentId,
      title: params.title,
      description: params.description,
      timeLimitMinutes: params.timeLimitMinutes,
      openAt: params.openAt,
      closeAt: params.closeAt,
      showResultsImmediately: params.showResultsImmediately,
    );
  }
}
