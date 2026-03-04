import 'package:flutter/foundation.dart';
import 'package:likha/core/errors/exceptions.dart';
import 'package:likha/core/sync/sync_queue.dart';
import 'package:uuid/uuid.dart';
import '../assessment_local_datasource_base.dart';

mixin AssessmentCreateMixin on AssessmentLocalDataSourceBase {
  @override
  Future<String> createAssessmentLocally({
    required String classId,
    required String title,
    String? description,
    required int timeLimitMinutes,
    required String openAt,
    required String closeAt,
    bool? showResultsImmediately,
  }) async {
    try {
      final db = await localDatabase.database;
      final assessmentId = const Uuid().v4();
      final now = DateTime.now();

      await db.transaction((txn) async {
        await txn.insert(
          'assessments',
          {
            'id': assessmentId,
            'local_id': assessmentId,
            'class_id': classId,
            'title': title,
            if (description != null) 'description': description,
            'time_limit_minutes': timeLimitMinutes,
            'open_at': openAt,
            'close_at': closeAt,
            'show_results_immediately': (showResultsImmediately ?? false) ? 1 : 0,
            'results_released': 0,
            'is_published': 0,
            'total_points': 0,
            'question_count': 0,
            'submission_count': 0,
            'created_at': now.toIso8601String(),
            'updated_at': now.toIso8601String(),
            'cached_at': now.toIso8601String(),
            'sync_status': 'pending',
            'is_offline_mutation': 1,
          },
        );

        await syncQueue.enqueue(
          SyncQueueEntry(
            id: const Uuid().v4(),
            entityType: SyncEntityType.assessment,
            operation: SyncOperation.create,
            payload: {
              'local_id': assessmentId,
              'class_id': classId,
              'title': title,
              if (description != null) 'description': description,
              'time_limit_minutes': timeLimitMinutes,
              'open_at': openAt,
              'close_at': closeAt,
              if (showResultsImmediately != null) 'show_results_immediately': showResultsImmediately,
            },
            status: SyncStatus.pending,
            retryCount: 0,
            maxRetries: 5,
            createdAt: now,
          ),
          txn: txn,
        );
      });

      return assessmentId;
    } catch (e) {
      throw CacheException('Failed to create assessment locally: $e');
    }
  }
}