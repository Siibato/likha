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
  final int orderIndex;
  final int totalPoints;
  final int questionCount;
  final int submissionCount;
  final bool? isSubmitted; // null if no submission, true if submitted, false if started but not submitted
  final String? linkedTosId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? cachedAt;
  final bool needsSync;

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
    required this.orderIndex,
    required this.totalPoints,
    required this.questionCount,
    required this.submissionCount,
    this.isSubmitted,
    this.linkedTosId,
    required this.createdAt,
    required this.updatedAt,
    this.cachedAt,
    this.needsSync = false,
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
        orderIndex,
        totalPoints,
        questionCount,
        submissionCount,
        isSubmitted,
        linkedTosId,
        createdAt,
        updatedAt,
        cachedAt,
        needsSync,
      ];
}
