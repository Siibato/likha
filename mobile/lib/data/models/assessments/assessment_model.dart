import 'package:likha/domain/assessments/entities/assessment.dart';

/// Server sends datetime strings in various formats. Normalize to UTC.
/// Dart's DateTime.parse treats bare strings as local time, causing
/// assessment open/close window comparisons to fail when device timezone ≠ server timezone.
/// This parser ensures UTC interpretation by stripping any timezone info and appending Z.
/// Handles: "2026-03-10T15:41:38" → "2026-03-10T15:41:38Z"
///          "2026-03-10T15:41:38Z" → "2026-03-10T15:41:38Z"
///          "2026-03-10T15:41:38+00:00Z" → "2026-03-10T15:41:38Z" (malformed, but handled)
DateTime _parseUtc(String s) {
  // Remove trailing Z and any timezone offset info, then re-add Z to force UTC
  String normalized = s.replaceAll(RegExp(r'(Z|[+-]\d{2}:\d{2}(Z)?)$'), '');
  // Normalize space separator to T (server may send space, Dart parser expects T)
  normalized = normalized.replaceFirst(' ', 'T');
  return DateTime.parse('${normalized}Z');
}

class AssessmentModel extends Assessment {
  final DateTime? deletedAt;

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
    super.isSubmitted,
    super.tosId,
    super.gradingPeriodNumber,
    super.component,
    required super.createdAt,
    required super.updatedAt,
    super.cachedAt,
    super.needsSync = false,
    this.deletedAt,
  });

  factory AssessmentModel.fromJson(Map<String, dynamic> json) {
    return AssessmentModel(
      id: json['id'] as String,
      classId: json['class_id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      timeLimitMinutes: json['time_limit_minutes'] as int,
      openAt: _parseUtc(json['open_at'] as String),
      closeAt: _parseUtc(json['close_at'] as String),
      showResultsImmediately: _parseBool(json['show_results_immediately']),
      resultsReleased: _parseBool(json['results_released']),
      isPublished: _parseBool(json['is_published']),
      orderIndex: json['order_index'] as int? ?? 0,
      totalPoints: json['total_points'] as int,
      questionCount: (json['questions'] as List<dynamic>?)?.length
          ?? json['question_count'] as int?
          ?? 0,
      submissionCount: json['submission_count'] as int? ?? 0,
      tosId: json['tos_id'] as String? ?? json['linked_tos_id'] as String?,
      gradingPeriodNumber: (json['grading_period_number'] as num?)?.toInt() ?? (json['quarter'] as num?)?.toInt(),
      component: json['component'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      deletedAt: json['deleted_at'] != null
          ? DateTime.parse(json['deleted_at'] as String)
          : null,
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
      openAt: _parseUtc(map['open_at'] as String),
      closeAt: _parseUtc(map['close_at'] as String),
      showResultsImmediately: (map['show_results_immediately'] as int?) == 1,
      resultsReleased: (map['results_released'] as int?) == 1,
      isPublished: (map['is_published'] as int?) == 1,
      orderIndex: map['order_index'] as int? ?? 0,
      totalPoints: (map['total_points'] as num?)?.toInt() ?? 0,
      questionCount: map['question_count'] as int? ?? 0,
      submissionCount: map['submission_count'] as int? ?? 0,
      tosId: map['tos_id'] as String? ?? map['linked_tos_id'] as String?,
      gradingPeriodNumber: (map['grading_period_number'] as num?)?.toInt() ?? (map['quarter'] as num?)?.toInt(),
      component: map['component'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
      deletedAt: map['deleted_at'] != null
          ? DateTime.parse(map['deleted_at'] as String)
          : null,
      cachedAt: map['cached_at'] != null
          ? DateTime.parse(map['cached_at'] as String)
          : null,
      needsSync: (map['needs_sync'] as int?) == 1,
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
      'tos_id': tosId,
      'grading_period_number': gradingPeriodNumber,
      'component': component,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'deleted_at': deletedAt?.toIso8601String(),
      'cached_at': cachedAt?.toIso8601String(),
      'needs_sync': needsSync ? 1 : 0,
    };
  }
}
