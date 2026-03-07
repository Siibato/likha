import 'package:equatable/equatable.dart';

class Assessment extends Equatable {
  final String id;
  final String classId;
  final String title;
  final String? description;
  final int timeLimitMinutes;
  final DateTime openAt;
  final DateTime closeAt;
  final bool showResultsImmediately;
  final bool resultsReleased;
  final bool isPublished;
  final int totalPoints;
  final int questionCount;
  final int submissionCount;
  final bool? isSubmitted; // null if no submission, true if submitted, false if started but not submitted
  final DateTime createdAt;
  final DateTime updatedAt;

  const Assessment({
    required this.id,
    required this.classId,
    required this.title,
    this.description,
    required this.timeLimitMinutes,
    required this.openAt,
    required this.closeAt,
    required this.showResultsImmediately,
    required this.resultsReleased,
    required this.isPublished,
    required this.totalPoints,
    required this.questionCount,
    required this.submissionCount,
    this.isSubmitted,
    required this.createdAt,
    required this.updatedAt,
  });

  @override
  List<Object?> get props => [
        id,
        classId,
        title,
        description,
        timeLimitMinutes,
        openAt,
        closeAt,
        showResultsImmediately,
        resultsReleased,
        isPublished,
        totalPoints,
        questionCount,
        submissionCount,
        isSubmitted,
        createdAt,
        updatedAt,
      ];
}
