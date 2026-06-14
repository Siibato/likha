import 'package:likha/core/database/db_schema.dart';
import 'package:likha/core/database/local_database.dart';
import 'package:likha/core/errors/exceptions.dart';
import 'package:likha/core/sync/sync_queue.dart';
import 'package:uuid/uuid.dart';

Future<String> startAssessment(
  LocalDatabase localDatabase,
  SyncQueue syncQueue,
  String assessmentId,
  String studentId,
  String studentName,
  String studentUsername,
) async {
  try {
    final db = await localDatabase.database;
    final localId = const Uuid().v4();
    final now = DateTime.now();
    await db.transaction((txn) async {
      await txn.insert(DbTables.assessmentSubmissions, {
        CommonCols.id: localId,
        AssessmentSubmissionsCols.assessmentId: assessmentId,
        AssessmentSubmissionsCols.userId: studentId,
        AssessmentSubmissionsCols.startedAt: now.toIso8601String(),
        AssessmentSubmissionsCols.totalPoints: 0,
        CommonCols.createdAt: now.toIso8601String(),
        CommonCols.updatedAt: now.toIso8601String(),
        CommonCols.cachedAt: now.toIso8601String(),
        CommonCols.syncStatus: 'pending',
      });
      await syncQueue.enqueue(SyncQueueEntry(
        id: const Uuid().v4(),
        entityType: SyncEntityType.assessmentSubmission,
        operation: SyncOperation.create,
        payload: {'id': localId, 'assessment_id': assessmentId, 'user_id': studentId},
        status: SyncStatus.pending,
        retryCount: 0,
        maxRetries: 3,
        createdAt: now,
      ), txn: txn);
    });
    return localId;
  } catch (e) {
    throw CacheException('Failed to start assessment locally: $e');
  }
}
