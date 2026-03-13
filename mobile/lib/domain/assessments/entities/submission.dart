import 'package:equatable/equatable.dart';

class SubmissionSummary extends Equatable {
  final String id;
  final String assessmentId;
  final String studentId;
  final String studentName;
  final String studentUsername;
  final DateTime startedAt;
  final DateTime? submittedAt;
  final double autoScore;
  final double finalScore;
  final int totalPoints;
  final bool isSubmitted;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? cachedAt;
  final bool needsSync;

  const SubmissionSummary({
    required this.id,
    required this.assessmentId,
    required this.studentId,
    required this.studentName,
    required this.studentUsername,
    required this.startedAt,
    this.submittedAt,
    required this.autoScore,
    required this.finalScore,
    required this.totalPoints,
    required this.isSubmitted,
    this.createdAt,
    this.updatedAt,
    this.cachedAt,
    this.needsSync = false,
  });

  @override
  List<Object?> get props => [id, assessmentId, studentId, totalPoints, isSubmitted, needsSync, cachedAt];
}

class SubmissionDetail extends Equatable {
  final String id;
  final String assessmentId;
  final String studentId;
  final String studentName;
  final DateTime startedAt;
  final DateTime? submittedAt;
  final double autoScore;
  final double finalScore;
  final bool isSubmitted;
  final int totalPoints;
  final List<SubmissionAnswer> answers;

  const SubmissionDetail({
    required this.id,
    required this.assessmentId,
    required this.studentId,
    required this.studentName,
    required this.startedAt,
    this.submittedAt,
    required this.autoScore,
    required this.finalScore,
    required this.isSubmitted,
    required this.totalPoints,
    required this.answers,
  });

  @override
  List<Object?> get props => [id, assessmentId, studentId];
}

class SubmissionAnswer extends Equatable {
  final String id;
  final String questionId;
  final String questionText;
  final String questionType;
  final int points;
  final String? answerText;
  final List<SelectedChoice>? selectedChoices;
  final List<EnumerationAnswer>? enumerationAnswers;
  final bool? isAutoCorrect;
  final bool? isOverrideCorrect;
  final double pointsAwarded;

  const SubmissionAnswer({
    required this.id,
    required this.questionId,
    required this.questionText,
    required this.questionType,
    required this.points,
    this.answerText,
    this.selectedChoices,
    this.enumerationAnswers,
    this.isAutoCorrect,
    this.isOverrideCorrect,
    required this.pointsAwarded,
  });

  @override
  List<Object?> get props => [id, questionId, pointsAwarded];
}

class SelectedChoice extends Equatable {
  final String choiceId;
  final String choiceText;
  final bool isCorrect;

  const SelectedChoice({
    required this.choiceId,
    required this.choiceText,
    required this.isCorrect,
  });

  @override
  List<Object?> get props => [choiceId, choiceText, isCorrect];
}

class EnumerationAnswer extends Equatable {
  final String id;
  final String answerText;
  final String? matchedItemId;
  final bool? isAutoCorrect;
  final bool? isOverrideCorrect;

  const EnumerationAnswer({
    required this.id,
    required this.answerText,
    this.matchedItemId,
    this.isAutoCorrect,
    this.isOverrideCorrect,
  });

  @override
  List<Object?> get props => [id, answerText];
}

class StartSubmissionResult extends Equatable {
  final String submissionId;
  final DateTime startedAt;
  final List<dynamic> questions;

  const StartSubmissionResult({
    required this.submissionId,
    required this.startedAt,
    required this.questions,
  });

  @override
  List<Object?> get props => [submissionId, startedAt];
}

class StudentResult extends Equatable {
  final String submissionId;
  final double autoScore;
  final double finalScore;
  final int totalPoints;
  final DateTime? submittedAt;
  final List<StudentAnswerResult> answers;

  const StudentResult({
    required this.submissionId,
    required this.autoScore,
    required this.finalScore,
    required this.totalPoints,
    this.submittedAt,
    required this.answers,
  });

  @override
  List<Object?> get props => [submissionId, finalScore, totalPoints];
}

class StudentAnswerResult extends Equatable {
  final String questionId;
  final String questionText;
  final String questionType;
  final int points;
  final double pointsAwarded;
  final bool? isCorrect;
  final String? answerText;
  final List<String>? selectedChoices;
  final List<StudentEnumAnswerResult>? enumerationAnswers;
  final List<String>? correctAnswers;

  const StudentAnswerResult({
    required this.questionId,
    required this.questionText,
    required this.questionType,
    required this.points,
    required this.pointsAwarded,
    this.isCorrect,
    this.answerText,
    this.selectedChoices,
    this.enumerationAnswers,
    this.correctAnswers,
  });

  @override
  List<Object?> get props => [questionId, pointsAwarded];
}

class StudentEnumAnswerResult extends Equatable {
  final String answerText;
  final bool? isCorrect;

  const StudentEnumAnswerResult({
    required this.answerText,
    this.isCorrect,
  });

  @override
  List<Object?> get props => [answerText, isCorrect];
}
