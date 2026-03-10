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
    required super.orderIndex,
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
      showResultsImmediately: _parseBool(json['show_results_immediately']),
      resultsReleased: _parseBool(json['results_released']),
      isPublished: _parseBool(json['is_published']),
      orderIndex: json['order_index'] as int? ?? 0,
      totalPoints: json['total_points'] as int,
      questionCount: (json['questions'] as List<dynamic>?)?.length
          ?? json['question_count'] as int?
          ?? 0,
      submissionCount: json['submission_count'] as int? ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  static bool _parseBool(dynamic value) {
    if (value is bool) return value;
    if (value is int) return value == 1;
    if (value is String) return value.toLowerCase() == 'true' || value == '1';
    return false;
  }

  factory AssessmentModel.fromMap(Map<String, dynamic> map) {
    return AssessmentModel(
      id: map['id'] as String,
      classId: map['class_id'] as String,
      title: map['title'] as String,
      description: map['description'] as String?,
      timeLimitMinutes: map['time_limit_minutes'] as int,
      openAt: DateTime.parse(map['open_at'] as String),
      closeAt: DateTime.parse(map['close_at'] as String),
      showResultsImmediately: (map['show_results_immediately'] as int?) == 1,
      resultsReleased: (map['results_released'] as int?) == 1,
      isPublished: (map['is_published'] as int?) == 1,
      orderIndex: map['order_index'] as int? ?? 0,
      totalPoints: map['total_points'] as int,
      questionCount: map['question_count'] as int? ?? 0,
      submissionCount: map['submission_count'] as int? ?? 0,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'class_id': classId,
      'title': title,
      'description': description,
      'time_limit_minutes': timeLimitMinutes,
      'open_at': openAt.toIso8601String(),
      'close_at': closeAt.toIso8601String(),
      'show_results_immediately': showResultsImmediately ? 1 : 0,
      'results_released': resultsReleased ? 1 : 0,
      'is_published': isPublished ? 1 : 0,
      'order_index': orderIndex,
      'total_points': totalPoints,
      'question_count': questionCount,
      'submission_count': submissionCount,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
