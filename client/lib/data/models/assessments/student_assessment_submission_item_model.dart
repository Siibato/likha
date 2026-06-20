import 'package:likha/data/models/assessments/submission_model.dart';

class StudentAssessmentSubmissionItemModel {
  final String assessmentId;
  final String id; // submission id
  final String studentId;
  final String studentName;
  final String studentUsername;
  final DateTime startedAt;
  final DateTime? submittedAt;
  final double totalPoints;

  const StudentAssessmentSubmissionItemModel({
    required this.assessmentId,
    required this.id,
    required this.studentId,
    required this.studentName,
    required this.studentUsername,
    required this.startedAt,
    required this.submittedAt,
    required this.totalPoints,
  });

  factory StudentAssessmentSubmissionItemModel.fromMap(Map<String, dynamic> map) {
    return StudentAssessmentSubmissionItemModel(
      assessmentId: map['assessment_id'] as String,
      id: map['id'] as String,
      studentId: map['student_id'] as String,
      studentName: map['student_name'] as String,
      studentUsername: map['student_username'] as String,
      startedAt: DateTime.parse(map['started_at'] as String),
      submittedAt: map['submitted_at'] != null ? DateTime.parse(map['submitted_at'] as String) : null,
      totalPoints: (map['total_points'] as num?)?.toDouble() ?? 0.0,
    );
  }

  SubmissionSummaryModel toSubmissionSummaryModel() {
    return SubmissionSummaryModel(
      id: id,
      assessmentId: assessmentId,
      studentId: studentId,
      studentName: studentName,
      studentUsername: studentUsername,
      startedAt: startedAt,
      submittedAt: submittedAt,
      autoScore: 0.0,
      finalScore: 0.0,
      totalPoints: totalPoints,
      isSubmitted: submittedAt != null,
    );
  }
}
