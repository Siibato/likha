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
    super.submissionStatus,
    super.submissionId,
    super.score,
    required super.createdAt,
    required super.updatedAt,
  });

  factory AssignmentModel.fromJson(Map<String, dynamic> json) {
    return AssignmentModel(
      id: json['id'] as String,
      classId: json['class_id'] as String? ?? json['assignment_id'] as String,
      title: json['title'] as String,
      instructions: json['instructions'] as String? ?? '',
      totalPoints: json['total_points'] as int,
      submissionType: json['submission_type'] as String,
      allowedFileTypes: json['allowed_file_types'] as String?,
      maxFileSizeMb: json['max_file_size_mb'] as int?,
      dueAt: _parseUtc(json['due_at'] as String),
      isPublished: json['is_published'] as bool,
      submissionCount: json['submission_count'] as int? ?? 0,
      gradedCount: json['graded_count'] as int? ?? 0,
      submissionStatus: json['submission_status'] as String?,
      submissionId: json['submission_id'] as String?,
      score: json['score'] as int?,
      createdAt: json['created_at'] != null ? _parseUtc(json['created_at'] as String) : DateTime.now(),
      updatedAt: json['updated_at'] != null ? _parseUtc(json['updated_at'] as String) : DateTime.now(),
    );
  }

  factory AssignmentModel.fromMap(Map<String, dynamic> map) {
    return AssignmentModel(
      id: map['id'] as String,
      classId: map['class_id'] as String,
      title: map['title'] as String,
      instructions: map['instructions'] as String? ?? '',
      totalPoints: map['total_points'] as int,
      submissionType: map['submission_type'] as String,
      allowedFileTypes: map['allowed_file_types'] as String?,
      maxFileSizeMb: map['max_file_size_mb'] as int?,
      dueAt: DateTime.parse(map['due_at'] as String),
      isPublished: (map['is_published'] as int?) == 1,
      submissionCount: map['submission_count'] as int? ?? 0,
      gradedCount: map['graded_count'] as int? ?? 0,
      submissionStatus: map['submission_status'] as String?,
      submissionId: map['submission_id'] as String?,
      score: map['score'] as int?,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'class_id': classId,
      'title': title,
      'instructions': instructions,
      'total_points': totalPoints,
      'submission_type': submissionType,
      'allowed_file_types': allowedFileTypes,
      'max_file_size_mb': maxFileSizeMb,
      'due_at': dueAt.toIso8601String(),
      'is_published': isPublished ? 1 : 0,
      'submission_count': submissionCount,
      'graded_count': gradedCount,
      'submission_status': submissionStatus,
      'submission_id': submissionId,
      'score': score,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
