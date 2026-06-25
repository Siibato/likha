import 'package:likha/core/database/db_schema.dart';
import 'package:likha/core/errors/exceptions.dart';
import 'package:likha/core/database/local_database.dart';
import 'package:likha/core/sync/sync_queue.dart';
import 'package:uuid/uuid.dart';

Future<String> createSubmission(
  LocalDatabase localDatabase,
  SyncQueue syncQueue,
  String assignmentId,
  String studentId,
  String studentName,
  String? textContent, {
  String? queueEntryId,
}) async {
  try {
    final db = await localDatabase.database;
    final now = DateTime.now();

    // Check for existing submission (UNIQUE constraint: one per student per assignment)
    final existing = await db.query(
      DbTables.assignmentSubmissions,
      columns: [CommonCols.id],
      where: '${AssignmentSubmissionsCols.assignmentId} = ? AND ${AssignmentSubmissionsCols.studentId} = ?',
      whereArgs: [assignmentId, studentId],
      limit: 1,
    );

    if (existing.isNotEmpty) {
      // Upsert: update text on the existing row, enqueue an update op
      final existingId = existing.first[CommonCols.id] as String;
      await db.transaction((txn) async {
        await txn.update(
          DbTables.assignmentSubmissions,
          {
            AssignmentSubmissionsCols.textContent: textContent ?? '',
            AssignmentSubmissionsCols.status: DbValues.statusDraft,
            CommonCols.updatedAt: now.toIso8601String(),
            CommonCols.cachedAt: now.toIso8601String(),
            CommonCols.syncStatus: 'pending',
          },
          where: '${CommonCols.id} = ?',
          whereArgs: [existingId],
        );
        await syncQueue.enqueue(SyncQueueEntry(
          id: queueEntryId ?? const Uuid().v4(),
          entityType: SyncEntityType.assignmentSubmission,
          operation: SyncOperation.update,
          payload: {'submission_id': existingId, 'text_content': textContent ?? ''},
          status: SyncStatus.pending,
          retryCount: 0,
          maxRetries: 3,
          createdAt: now,
        ), txn: txn);
      });
      return existingId;
    }

    // Fresh insert
    final submissionId = const Uuid().v4();
    await db.transaction((txn) async {
      await txn.insert(
        DbTables.assignmentSubmissions,
        {
          CommonCols.id: submissionId,
          AssignmentSubmissionsCols.assignmentId: assignmentId,
          AssignmentSubmissionsCols.studentId: studentId,
          AssignmentSubmissionsCols.status: DbValues.statusDraft,
          AssignmentSubmissionsCols.textContent: textContent ?? '',
          CommonCols.createdAt: now.toIso8601String(),
          CommonCols.updatedAt: now.toIso8601String(),
          CommonCols.cachedAt: now.toIso8601String(),
          CommonCols.syncStatus: 'pending',
        },
      );
      await syncQueue.enqueue(SyncQueueEntry(
        id: queueEntryId ?? const Uuid().v4(),
        entityType: SyncEntityType.assignmentSubmission,
        operation: SyncOperation.create,
        payload: {
          'id': submissionId,
          'assignment_id': assignmentId,
          'student_id': studentId,
          if (textContent != null) 'text_content': textContent,
        },
        status: SyncStatus.pending,
        retryCount: 0,
        maxRetries: 3,
        createdAt: now,
      ), txn: txn);
    });
    return submissionId;
  } catch (e) {
    throw CacheException('Failed to create submission locally: $e');
  }
}
