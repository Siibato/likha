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
        createdAt,
        updatedAt,
      ];
}
