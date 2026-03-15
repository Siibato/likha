import 'package:likha/data/models/assignments/submission_file_model.dart';
import 'package:likha/domain/assignments/entities/assignment_submission.dart';

/// Server sends NaiveDateTime (UTC without Z suffix).
DateTime _parseUtc(String s) =>
    DateTime.parse(s.endsWith('Z') ? s : '${s}Z');

class AssignmentSubmissionModel extends AssignmentSubmission {
  final DateTime? deletedAt;

  const AssignmentSubmissionModel({
    required super.id,
    required super.assignmentId,
    required super.studentId,
    required super.studentName,
    required super.status,
    super.textContent,
    super.submittedAt,
    required super.isLate,
    super.score,
    super.feedback,
    super.gradedAt,
    super.gradedBy,
    required super.files,
    required super.createdAt,
    required super.updatedAt,
    super.cachedAt,
    super.needsSync = false,
    this.deletedAt,
  });

  factory AssignmentSubmissionModel.fromJson(Map<String, dynamic> json) {
    return AssignmentSubmissionModel(
      id: json['id'] as String,
      assignmentId: json['assignment_id'] as String,
      studentId: json['student_id'] as String,
      studentName: json['student_name'] as String,
      status: json['status'] as String,
      textContent: json['text_content'] as String?,
      submittedAt: json['submitted_at'] != null
          ? _parseUtc(json['submitted_at'] as String)
          : null,
      isLate: json['is_late'] as bool? ?? false,
      score: json['score'] as int?,
      feedback: json['feedback'] as String?,
      gradedAt: json['graded_at'] != null
          ? _parseUtc(json['graded_at'] as String)
          : null,
      files: (json['files'] as List<dynamic>?)
              ?.map(
                  (e) => SubmissionFileModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      createdAt: _parseUtc(json['created_at'] as String),
      updatedAt: _parseUtc(json['updated_at'] as String),
      gradedBy: json['graded_by'] as String?,
      deletedAt: json['deleted_at'] != null
          ? _parseUtc(json['deleted_at'] as String)
          : null,
    );
  }

  factory AssignmentSubmissionModel.fromMap(Map<String, dynamic> map) {
    return AssignmentSubmissionModel(
      id: map['id'] as String,
      assignmentId: map['assignment_id'] as String,
      studentId: map['student_id'] as String,
      studentName: map['student_name'] as String? ?? '',
      status: map['status'] as String,
      textContent: map['text_content'] as String?,
      submittedAt: map['submitted_at'] != null
          ? DateTime.parse(map['submitted_at'] as String)
          : null,
      isLate: (map['is_late'] as int?) == 1,
      score: map['points'] as int?,
      feedback: map['feedback'] as String?,
      gradedAt: map['graded_at'] != null
          ? DateTime.parse(map['graded_at'] as String)
          : null,
      files: [],
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
      gradedBy: map['graded_by'] as String?,
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
      'assignment_id': assignmentId,
      'student_id': studentId,
      'status': status,
      'text_content': textContent,
      'submitted_at': submittedAt?.toIso8601String(),
      'is_late': isLate ? 1 : 0,
      'points': score,
      'feedback': feedback,
      'graded_at': gradedAt?.toIso8601String(),
      'graded_by': gradedBy,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'deleted_at': deletedAt?.toIso8601String(),
      'cached_at': cachedAt?.toIso8601String(),
      'needs_sync': needsSync ? 1 : 0,
    };
  }
}

class SubmissionListItemModel extends SubmissionListItem {
  const SubmissionListItemModel({
    required super.id,
    required super.studentId,
    required super.studentName,
    required super.studentUsername,
    required super.status,
    super.submittedAt,
    required super.isLate,
    super.score,
  });

  factory SubmissionListItemModel.fromJson(Map<String, dynamic> json) {
    return SubmissionListItemModel(
      id: json['id'] as String,
      studentId: json['student_id'] as String,
      studentName: json['student_name'] as String,
      studentUsername: json['student_username'] as String? ?? '',
      status: json['status'] as String,
      submittedAt: json['submitted_at'] != null
          ? _parseUtc(json['submitted_at'] as String)
          : null,
      isLate: json['is_late'] as bool? ?? false,
      score: json['score'] as int?,
    );
  }
}

class StudentAssignmentListItemModel extends StudentAssignmentListItem {
  const StudentAssignmentListItemModel({
    required super.id,
    required super.title,
    required super.totalPoints,
    required super.submissionType,
    required super.dueAt,
    required super.isPublished,
    super.submissionStatus,
    super.score,
  });

  factory StudentAssignmentListItemModel.fromJson(Map<String, dynamic> json) {
    return StudentAssignmentListItemModel(
      id: json['id'] as String,
      title: json['title'] as String,
      totalPoints: json['total_points'] as int,
      submissionType: json['submission_type'] as String,
      dueAt: _parseUtc(json['due_at'] as String),
      isPublished: json['is_published'] as bool? ?? false,
      submissionStatus: json['submission_status'] as String?,
      score: json['score'] as int?,
    );
  }
}
