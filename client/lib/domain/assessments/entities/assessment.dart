import 'package:equatable/equatable.dart';
import 'package:likha/core/sync/sync_queue.dart';

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
  final String? tosId;
  final int? gradingPeriodNumber;
  final String? component;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? cachedAt;
  final SyncStatus syncStatus;

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
    this.tosId,
    this.gradingPeriodNumber,
    this.component,
    required this.createdAt,
    required this.updatedAt,
    this.cachedAt,
    this.syncStatus = SyncStatus.synced,
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
        tosId,
        gradingPeriodNumber,
        component,
        createdAt,
        updatedAt,
        cachedAt,
        syncStatus,
      ];
}
