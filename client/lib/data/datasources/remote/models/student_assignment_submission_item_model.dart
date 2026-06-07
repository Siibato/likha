import 'package:likha/data/models/assignments/assignment_submission_model.dart';

class StudentAssignmentSubmissionItemModel {
  final String assignmentId;
  final String id;
  final String studentId;
  final String studentName;
  final String status;
  final DateTime? submittedAt;
  final bool isLate;
  final int? score;

  const StudentAssignmentSubmissionItemModel({
    required this.assignmentId,
    required this.id,
    required this.studentId,
    required this.studentName,
    required this.status,
    required this.submittedAt,
    required this.isLate,
    required this.score,
  });

  factory StudentAssignmentSubmissionItemModel.fromMap(Map<String, dynamic> map) {
    return StudentAssignmentSubmissionItemModel(
      assignmentId: map['assignment_id'] as String,
      id: map['id'] as String,
      studentId: map['student_id'] as String,
      studentName: map['student_name'] as String,
      status: map['status'] as String,
      submittedAt: map['submitted_at'] != null ? DateTime.parse(map['submitted_at'] as String) : null,
      isLate: map['is_late'] as bool,
      score: map['score'] as int?,
    );
  }

  SubmissionListItemModel toSubmissionListItemModel() {
    return SubmissionListItemModel(
      id: id,
      studentId: studentId,
      studentName: studentName,
      studentUsername: '', // Not available in this context
      status: status,
      submittedAt: submittedAt,
      score: score,
    );
  }
}
