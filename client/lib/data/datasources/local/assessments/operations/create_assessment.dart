import 'package:likha/core/database/db_schema.dart';
import 'package:likha/core/database/local_database.dart';
import 'package:likha/core/errors/exceptions.dart';
import 'package:likha/core/sync/sync_queue.dart';
import 'package:uuid/uuid.dart';

Future<String> createAssessment(
  LocalDatabase localDatabase,
  SyncQueue syncQueue,
  String classId,
  String title,
  String? description,
  int timeLimitMinutes,
  String openAt,
  String closeAt,
  bool? showResultsImmediately,
  bool isPublished,
  String? tosId,
  int? gradingPeriodNumber,
  String? component,
) async {
  try {
    final db = await localDatabase.database;
    final now = DateTime.now();
    final assessmentId = const Uuid().v4();
    await db.transaction((txn) async {
      await txn.insert(DbTables.assessments, {
        CommonCols.id: assessmentId,
        AssessmentsCols.classId: classId,
        AssessmentsCols.title: title,
        AssessmentsCols.description: description,
        AssessmentsCols.timeLimitMinutes: timeLimitMinutes,
        AssessmentsCols.openAt: openAt,
        AssessmentsCols.closeAt: closeAt,
        AssessmentsCols.showResultsImmediately: showResultsImmediately == true ? 1 : 0,
        AssessmentsCols.resultsReleased: 0,
        AssessmentsCols.isPublished: isPublished ? 1 : 0,
        AssessmentsCols.orderIndex: 0,
        if (tosId != null) AssessmentsCols.tosId: tosId,
        if (gradingPeriodNumber != null) AssessmentsCols.gradingPeriodNumber: gradingPeriodNumber,
        if (component != null) AssessmentsCols.component: component,
        CommonCols.createdAt: now.toIso8601String(),
        CommonCols.updatedAt: now.toIso8601String(),
        CommonCols.cachedAt: now.toIso8601String(),
        CommonCols.needsSync: 1,
      });

      await syncQueue.enqueue(
        SyncQueueEntry(
          id: const Uuid().v4(),
          entityType: SyncEntityType.assessment,
          operation: SyncOperation.create,
          payload: {
            'id': assessmentId,
            'class_id': classId,
            'title': title,
            if (description != null) 'description': description,
            'time_limit_minutes': timeLimitMinutes,
            'open_at': openAt,
            'close_at': closeAt,
            if (showResultsImmediately != null) 'show_results_immediately': showResultsImmediately,
            'is_published': isPublished,
            if (tosId != null) 'tos_id': tosId,
            if (gradingPeriodNumber != null) 'grading_period_number': gradingPeriodNumber,
            if (component != null) 'component': component,
          },
          status: SyncStatus.pending,
          retryCount: 0,
          maxRetries: 3,
          createdAt: now,
        ),
        txn: txn,
      );
    });

    final verifyResult = await db.query(
      'assessments',
      where: '${CommonCols.id} = ?',
      whereArgs: [assessmentId],
      limit: 1,
    );

    if (verifyResult.isEmpty) {
      throw CacheException('Failed to verify assessment creation: assessment not found in database');
    }

    return assessmentId;
  } catch (e) {
    throw CacheException('Failed to create assessment locally: $e');
  }
}
