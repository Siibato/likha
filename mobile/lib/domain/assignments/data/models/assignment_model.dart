import 'package:likha/domain/assignments/entities/assignment.dart';

/// Server sends NaiveDateTime (UTC without Z suffix).
DateTime _parseUtc(String s) =>
    DateTime.parse(s.endsWith('Z') ? s : '${s}Z');

class AssignmentModel extends Assignment {
  const AssignmentModel({
    required super.id,
    required super.classId,
    required super.title,
    required super.instructions,
    required super.totalPoints,
    required super.submissionType,
    super.allowedFileTypes,
    super.maxFileSizeMb,
    required super.dueAt,
    required super.isPublished,
    required super.submissionCount,
    required super.gradedCount,
    required super.createdAt,
    required super.updatedAt,
  });

  factory AssignmentModel.fromJson(Map<String, dynamic> json) {
    return AssignmentModel(
      id: json['id'] as String,
      classId: json['class_id'] as String,
      title: json['title'] as String,
      instructions: json['instructions'] as String,
      totalPoints: json['total_points'] as int,
      submissionType: json['submission_type'] as String,
      allowedFileTypes: json['allowed_file_types'] as String?,
      maxFileSizeMb: json['max_file_size_mb'] as int?,
      dueAt: _parseUtc(json['due_at'] as String),
      isPublished: json['is_published'] as bool,
      submissionCount: json['submission_count'] as int? ?? 0,
      gradedCount: json['graded_count'] as int? ?? 0,
      createdAt: _parseUtc(json['created_at'] as String),
      updatedAt: _parseUtc(json['updated_at'] as String),
    );
  }
}
