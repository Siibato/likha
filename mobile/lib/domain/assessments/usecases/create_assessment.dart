import 'package:likha/core/utils/typedef.dart';
import 'package:likha/domain/assessments/entities/assessment.dart';
import 'package:likha/domain/assessments/repositories/assessment_repository.dart';

class CreateAssessment {
  final AssessmentRepository _repository;

  CreateAssessment(this._repository);

  ResultFuture<Assessment> call(CreateAssessmentParams params) {
    return _repository.createAssessment(
      classId: params.classId,
      title: params.title,
      description: params.description,
      timeLimitMinutes: params.timeLimitMinutes,
      openAt: params.openAt,
      closeAt: params.closeAt,
      showResultsImmediately: params.showResultsImmediately,
      isPublished: params.isPublished,
      questions: params.questions,
      quarter: params.quarter,
      component: params.component,
      isDepartmentalExam: params.isDepartmentalExam,
      linkedTosId: params.linkedTosId,
    );
  }
}

class CreateAssessmentParams {
  final String classId;
  final String title;
  final String? description;
  final int timeLimitMinutes;
  final String openAt;
  final String closeAt;
  final bool? showResultsImmediately;
  final bool isPublished;
  final List<Map<String, dynamic>>? questions;
  final int? quarter;
  final String? component;
  final bool? isDepartmentalExam;
  final String? linkedTosId;

  CreateAssessmentParams({
    required this.classId,
    required this.title,
    this.description,
    required this.timeLimitMinutes,
    required this.openAt,
    required this.closeAt,
    this.showResultsImmediately,
    this.isPublished = true,
    this.questions,
    this.quarter,
    this.component,
    this.isDepartmentalExam,
    this.linkedTosId,
  });
}
