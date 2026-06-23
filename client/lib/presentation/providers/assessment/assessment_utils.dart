import 'package:likha/core/sync/sync_queue.dart';
import 'package:likha/domain/assessments/entities/assessment.dart';

Assessment withUpdatedAssessment(
  Assessment a, {
  bool? isPublished,
  bool? resultsReleased,
  String? title,
  String? description,
  int? timeLimitMinutes,
  DateTime? openAt,
  DateTime? closeAt,
  bool? showResultsImmediately,
  int? termNumber,
  String? component,
}) {
  return Assessment(
    id: a.id,
    classId: a.classId,
    title: title ?? a.title,
    description: description ?? a.description,
    timeLimitMinutes: timeLimitMinutes ?? a.timeLimitMinutes,
    openAt: openAt ?? a.openAt,
    closeAt: closeAt ?? a.closeAt,
    showResultsImmediately: showResultsImmediately ?? a.showResultsImmediately,
    resultsReleased: resultsReleased ?? a.resultsReleased,
    isPublished: isPublished ?? a.isPublished,
    orderIndex: a.orderIndex,
    totalPoints: a.totalPoints,
    questionCount: a.questionCount,
    submissionCount: a.submissionCount,
    isSubmitted: a.isSubmitted,
    tosId: a.tosId,
    termNumber: termNumber ?? a.termNumber,
    component: component ?? a.component,
    createdAt: a.createdAt,
    updatedAt: DateTime.now(),
    cachedAt: a.cachedAt,
    syncStatus: SyncStatus.pending,
  );
}

String toGradeComponent(String c) {
  switch (c) {
    case 'written_work':
      return 'ww';
    case 'performance_task':
      return 'pt';
    case 'term_assessment':
      return 'qa';
    default:
      return c;
  }
}
