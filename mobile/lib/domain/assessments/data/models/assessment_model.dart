import 'package:likha/domain/assessments/entities/assessment.dart';

class AssessmentModel extends Assessment {
  const AssessmentModel({
    required super.id,
    required super.classId,
    required super.title,
    super.description,
    required super.timeLimitMinutes,
    required super.openAt,
    required super.closeAt,
    required super.showResultsImmediately,
    required super.resultsReleased,
    required super.isPublished,
    required super.totalPoints,
    required super.questionCount,
    required super.submissionCount,
    required super.createdAt,
    required super.updatedAt,
  });

  factory AssessmentModel.fromJson(Map<String, dynamic> json) {
    return AssessmentModel(
      id: json['id'] as String,
      classId: json['class_id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      timeLimitMinutes: json['time_limit_minutes'] as int,
      openAt: DateTime.parse(json['open_at'] as String),
      closeAt: DateTime.parse(json['close_at'] as String),
      showResultsImmediately: json['show_results_immediately'] as bool,
      resultsReleased: json['results_released'] as bool,
      isPublished: json['is_published'] as bool,
      totalPoints: json['total_points'] as int,
      questionCount: json['question_count'] as int? ?? 0,
      submissionCount: json['submission_count'] as int? ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }
}
