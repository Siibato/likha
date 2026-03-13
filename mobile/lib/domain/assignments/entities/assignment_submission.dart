import 'package:equatable/equatable.dart';
import 'package:likha/domain/assignments/entities/submission_file.dart';

class AssignmentSubmission extends Equatable {
  final String id;
  final String assignmentId;
  final String studentId;
  final String studentName;
  final String status;
  final String? textContent;
  final DateTime? submittedAt;
  final bool isLate;
  final int? score;
  final String? feedback;
  final DateTime? gradedAt;
  final String? gradedBy;
  final List<SubmissionFile> files;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? cachedAt;
  final bool needsSync;

  const AssignmentSubmission({
    required this.id,
    required this.assignmentId,
    required this.studentId,
    required this.studentName,
    required this.status,
    this.textContent,
    this.submittedAt,
    required this.isLate,
    this.score,
    this.feedback,
    this.gradedAt,
    this.gradedBy,
    required this.files,
    required this.createdAt,
    required this.updatedAt,
    this.cachedAt,
    this.needsSync = false,
  });

  @override
  List<Object?> get props => [
        id,
        assignmentId,
        studentId,
        studentName,
        status,
        textContent,
        submittedAt,
        isLate,
        score,
        feedback,
        gradedAt,
        gradedBy,
        files,
        createdAt,
        updatedAt,
        cachedAt,
        needsSync,
      ];
}

class SubmissionListItem extends Equatable {
  final String id;
  final String studentId;
  final String studentName;
  final String status;
  final DateTime? submittedAt;
  final bool isLate;
  final int? score;

  const SubmissionListItem({
    required this.id,
    required this.studentId,
    required this.studentName,
    required this.status,
    this.submittedAt,
    required this.isLate,
    this.score,
  });

  @override
  List<Object?> get props =>
      [id, studentId, studentName, status, submittedAt, isLate, score];
}

class StudentAssignmentListItem extends Equatable {
  final String id;
  final String title;
  final int totalPoints;
  final String submissionType;
  final DateTime dueAt;
  final bool isPublished;
  final String? submissionStatus;
  final int? score;

  const StudentAssignmentListItem({
    required this.id,
    required this.title,
    required this.totalPoints,
    required this.submissionType,
    required this.dueAt,
    required this.isPublished,
    this.submissionStatus,
    this.score,
  });

  @override
  List<Object?> get props => [
        id,
        title,
        totalPoints,
        submissionType,
        dueAt,
        isPublished,
        submissionStatus,
        score,
      ];
}

class StudentAssignmentStatus extends Equatable {
  final String submissionId;
  final String status;   // draft | submitted | graded | returned
  final int? score;

  const StudentAssignmentStatus({
    required this.submissionId,
    required this.status,
    this.score,
  });

  @override
  List<Object?> get props => [submissionId, status, score];
}
