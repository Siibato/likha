import 'package:likha/data/models/assignments/submission_file_model.dart';
import 'package:likha/domain/assignments/entities/assignment_submission.dart';

/// Server sends NaiveDateTime (UTC without Z suffix).
DateTime _parseUtc(String s) =>
    DateTime.parse(s.endsWith('Z') ? s : '${s}Z');

class AssignmentSubmissionModel extends AssignmentSubmission {
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
    required super.files,
    required super.createdAt,
    required super.updatedAt,
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
      isLate: json['is_late'] as bool,
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
    );
  }
}

class SubmissionListItemModel extends SubmissionListItem {
  const SubmissionListItemModel({
    required super.id,
    required super.studentId,
    required super.studentName,
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
      status: json['status'] as String,
      submittedAt: json['submitted_at'] != null
          ? _parseUtc(json['submitted_at'] as String)
          : null,
      isLate: json['is_late'] as bool,
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
      isPublished: json['is_published'] as bool,
      submissionStatus: json['submission_status'] as String?,
      score: json['score'] as int?,
    );
  }
}
