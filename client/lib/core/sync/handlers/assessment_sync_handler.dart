import 'package:likha/core/database/db_schema.dart';
import 'package:likha/core/database/local_database.dart';
import 'package:likha/core/errors/exceptions.dart';
import 'package:likha/core/logging/sync_logger.dart';
import 'package:likha/core/sync/sync_queue.dart';
import 'package:likha/core/sync/sync_result.dart';
import 'package:likha/data/datasources/local/assessments/assessment_local_datasource.dart';
import 'package:likha/data/datasources/remote/assessments/assessment_remote_datasource.dart';
import 'package:likha/data/models/assessments/assessment_model.dart';

/// Sync handler for all [SyncEntityType.assessment] operations.
///
/// Invoked by the outbound sync engine for each pending assessment queue entry.
/// Sends the entry ID as `Idempotency-Key`, calls the corresponding remote
/// datasource method, and reconciles the server response into the local DB
/// with conflict resolution.
class AssessmentSyncHandler {
  final AssessmentRemoteDataSource _remote;
  final AssessmentLocalDataSource _local;
  final LocalDatabase _localDatabase;
  final SyncLogger _log;

  AssessmentSyncHandler(
    this._remote,
    this._local,
    this._localDatabase,
    this._log,
  );

  Future<SyncResult> handle(SyncQueueEntry entry) async {
    try {
      switch (entry.operation) {
        case SyncOperation.create:
          return await _handleCreate(entry);
        case SyncOperation.update:
          return await _handleUpdate(entry);
        case SyncOperation.delete:
          return await _handleDelete(entry);
        case SyncOperation.publish:
          return await _handlePublish(entry);
        case SyncOperation.unpublish:
          return await _handleUnpublish(entry);
        case SyncOperation.releaseResults:
          return await _handleReleaseResults(entry);
        case SyncOperation.start:
          return await _handleStart(entry);
        case SyncOperation.submit:
          return await _handleSubmit(entry);
        case SyncOperation.saveAnswers:
          return await _handleSaveAnswers(entry);
        case SyncOperation.gradeEssay:
          return await _handleGradeEssay(entry);
        case SyncOperation.overrideAnswer:
          return await _handleOverrideAnswer(entry);
        case SyncOperation.reorder:
          return await _handleReorder(entry);
        default:
          return SyncResult.permanentFailure(
            'Unsupported assessment operation: ${entry.operation}',
          );
      }
    } on NetworkException catch (e) {
      return SyncResult.retry(e.message);
    } on ServerException catch (e) {
      return SyncResult.permanentFailure(e.message);
    } catch (e) {
      return SyncResult.permanentFailure(e.toString());
    }
  }

  // --------------------------------------------------------------------------
  // Helpers
  // --------------------------------------------------------------------------

  /// Checks whether the local row in [table] with [id] was modified after
  /// the sync entry was created.
  Future<bool> _isLocalModifiedAfter(
    String table,
    String id,
    DateTime entryCreatedAt,
  ) async {
    final db = await _localDatabase.database;
    final rows = await db.query(
      table,
      columns: [CommonCols.updatedAt],
      where: '${CommonCols.id} = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return false;
    final updatedAtStr = rows.first[CommonCols.updatedAt] as String?;
    if (updatedAtStr == null) return false;
    final updatedAt = DateTime.tryParse(updatedAtStr);
    if (updatedAt == null) return false;
    return updatedAt.isAfter(entryCreatedAt);
  }

  /// Reconciles a server-returned [AssessmentModel] into the local DB.
  /// If the local row was modified after [entry.createdAt], data fields are
  /// **not** overwritten so newer local changes are preserved.
  Future<void> _reconcileAssessment(
    SyncQueueEntry entry,
    AssessmentModel model,
  ) async {
    final localId = entry.payload['id'] as String? ?? model.id;

    // ID reconciliation: server may return a different ID for creates.
    if (model.id != localId) {
      final db = await _localDatabase.database;
      await db.update(
        DbTables.assessments,
        {CommonCols.id: model.id},
        where: '${CommonCols.id} = ?',
        whereArgs: [localId],
      );
    }

    final conflict = await _isLocalModifiedAfter(
      DbTables.assessments,
      model.id,
      entry.createdAt,
    );

    if (!conflict) {
      await _local.cacheAssessments([model]);
    } else {
      _log.warn(
        'Conflict detected for assessment ${model.id}; '
        'skipping overwrite to preserve newer local changes.',
      );
      // Still mark as synced since the server processed the request.
      final db = await _localDatabase.database;
      await db.update(
        DbTables.assessments,
        {CommonCols.syncStatus: SyncStatus.synced.dbValue},
        where: '${CommonCols.id} = ?',
        whereArgs: [model.id],
      );
    }
  }

  Future<void> _markSynced(String table, String id) async {
    final db = await _localDatabase.database;
    await db.update(
      table,
      {CommonCols.syncStatus: SyncStatus.synced.dbValue},
      where: '${CommonCols.id} = ?',
      whereArgs: [id],
    );
  }

  // --------------------------------------------------------------------------
  // Operation handlers
  // --------------------------------------------------------------------------

  Future<SyncResult> _handleCreate(SyncQueueEntry entry) async {
    final payload = entry.payload;
    final classId = payload['class_id'] as String;
    final model = await _remote.createAssessment(
      classId: classId,
      data: payload,
      idempotencyKey: entry.id,
    );
    await _reconcileAssessment(entry, model);
    return SyncResult.success(serverId: model.id);
  }

  Future<SyncResult> _handleUpdate(SyncQueueEntry entry) async {
    final payload = entry.payload;
    final assessmentId = payload['id'] as String;
    final model = await _remote.updateAssessment(
      assessmentId: assessmentId,
      data: payload,
      idempotencyKey: entry.id,
    );
    await _reconcileAssessment(entry, model);
    return const SyncResult.success();
  }

  Future<SyncResult> _handleDelete(SyncQueueEntry entry) async {
    final assessmentId = entry.payload['id'] as String;
    await _remote.deleteAssessment(
      assessmentId: assessmentId,
      idempotencyKey: entry.id,
    );
    await _local.deleteAssessment(assessmentId: assessmentId);
    return const SyncResult.success();
  }

  Future<SyncResult> _handlePublish(SyncQueueEntry entry) async {
    final assessmentId = entry.payload['id'] as String;
    final model = await _remote.publishAssessment(
      assessmentId: assessmentId,
      idempotencyKey: entry.id,
    );
    await _reconcileAssessment(entry, model);
    return const SyncResult.success();
  }

  Future<SyncResult> _handleUnpublish(SyncQueueEntry entry) async {
    final assessmentId = entry.payload['id'] as String;
    final model = await _remote.unpublishAssessment(
      assessmentId: assessmentId,
      idempotencyKey: entry.id,
    );
    await _reconcileAssessment(entry, model);
    return const SyncResult.success();
  }

  Future<SyncResult> _handleReleaseResults(SyncQueueEntry entry) async {
    final assessmentId = entry.payload['id'] as String;
    final model = await _remote.releaseResults(
      assessmentId: assessmentId,
      idempotencyKey: entry.id,
    );
    await _reconcileAssessment(entry, model);
    return const SyncResult.success();
  }

  Future<SyncResult> _handleStart(SyncQueueEntry entry) async {
    final payload = entry.payload;
    final assessmentId = payload['assessment_id'] as String;
    final result = await _remote.startAssessment(
      assessmentId: assessmentId,
      idempotencyKey: entry.id,
    );
    await _local.cacheStartSubmissionResult(
      submissionId: result.submissionId,
      assessmentId: assessmentId,
      studentId: payload['student_id'] as String,
      studentName: payload['student_name'] as String,
      studentUsername: payload['student_username'] as String,
      startedAt: result.startedAt,
    );
    return SyncResult.success(serverId: result.submissionId);
  }

  Future<SyncResult> _handleSubmit(SyncQueueEntry entry) async {
    final payload = entry.payload;
    final submissionId = payload['submission_id'] as String;
    final result = await _remote.submitAssessment(
      submissionId: submissionId,
      idempotencyKey: entry.id,
    );
    await _local.cacheStudentSubmission(
      payload['assessment_id'] as String,
      payload['student_id'] as String,
      result,
    );
    return const SyncResult.success();
  }

  Future<SyncResult> _handleSaveAnswers(SyncQueueEntry entry) async {
    final payload = entry.payload;
    await _remote.saveAnswers(
      submissionId: payload['submission_id'] as String,
      answers: (payload['answers'] as List<dynamic>)
          .cast<Map<String, dynamic>>(),
      idempotencyKey: entry.id,
    );
    await _markSynced(
      DbTables.assessmentSubmissions,
      payload['submission_id'] as String,
    );
    return const SyncResult.success();
  }

  Future<SyncResult> _handleGradeEssay(SyncQueueEntry entry) async {
    final payload = entry.payload;
    final answerId = payload['answer_id'] as String;
    final points = (payload['points'] as num).toDouble();
    await _remote.gradeEssayAnswer(
      answerId: answerId,
      points: points,
      idempotencyKey: entry.id,
    );
    final db = await _localDatabase.database;
    await db.update(
      DbTables.submissionAnswers,
      {
        SubmissionAnswersCols.points: points,
        SubmissionAnswersCols.overriddenAt: DateTime.now().toIso8601String(),
        CommonCols.syncStatus: SyncStatus.synced.dbValue,
        CommonCols.cachedAt: DateTime.now().toIso8601String(),
      },
      where: '${CommonCols.id} = ?',
      whereArgs: [answerId],
    );
    await _recalculateAndUpdateSubmissionScore(answerId);
    return const SyncResult.success();
  }

  Future<SyncResult> _handleOverrideAnswer(SyncQueueEntry entry) async {
    final payload = entry.payload;
    final answerId = payload['answer_id'] as String;
    final isCorrect = payload['is_correct'] as bool;
    final points = payload['points'] != null
        ? (payload['points'] as num).toDouble()
        : null;
    await _remote.overrideAnswer(
      answerId: answerId,
      isCorrect: isCorrect,
      points: points,
      idempotencyKey: entry.id,
    );
    final db = await _localDatabase.database;
    final answerUpdates = <String, dynamic>{
      SubmissionAnswersCols.overriddenAt: DateTime.now().toIso8601String(),
      CommonCols.syncStatus: SyncStatus.synced.dbValue,
      CommonCols.cachedAt: DateTime.now().toIso8601String(),
    };
    if (points != null) {
      answerUpdates[SubmissionAnswersCols.points] = points;
    }
    await db.update(
      DbTables.submissionAnswers,
      answerUpdates,
      where: '${CommonCols.id} = ?',
      whereArgs: [answerId],
    );
    await db.update(
      DbTables.submissionAnswerItems,
      {
        SubmissionAnswerItemsCols.isCorrect: isCorrect ? 1 : 0,
        CommonCols.cachedAt: DateTime.now().toIso8601String(),
      },
      where: '${SubmissionAnswerItemsCols.submissionAnswerId} = ?',
      whereArgs: [answerId],
    );
    await _recalculateAndUpdateSubmissionScore(answerId);
    return const SyncResult.success();
  }

  /// Recalculates the total earned points for the submission that owns
  /// [answerId] and updates the parent [assessment_submissions] row.
  Future<void> _recalculateAndUpdateSubmissionScore(String answerId) async {
    final db = await _localDatabase.database;
    final rows = await db.query(
      DbTables.submissionAnswers,
      columns: [SubmissionAnswersCols.submissionId],
      where: '${CommonCols.id} = ?',
      whereArgs: [answerId],
      limit: 1,
    );
    if (rows.isEmpty) return;
    final submissionId = rows.first[SubmissionAnswersCols.submissionId] as String;

    final answerRows = await db.query(
      DbTables.submissionAnswers,
      columns: [SubmissionAnswersCols.points],
      where: '${SubmissionAnswersCols.submissionId} = ?',
      whereArgs: [submissionId],
    );
    double totalEarned = 0.0;
    for (final row in answerRows) {
      final p = row[SubmissionAnswersCols.points] as num?;
      if (p != null) totalEarned += p.toDouble();
    }

    await db.update(
      DbTables.assessmentSubmissions,
      {
        AssessmentSubmissionsCols.earnedPoints: totalEarned,
        CommonCols.syncStatus: SyncStatus.synced.dbValue,
        CommonCols.updatedAt: DateTime.now().toIso8601String(),
      },
      where: '${CommonCols.id} = ?',
      whereArgs: [submissionId],
    );
  }

  Future<SyncResult> _handleReorder(SyncQueueEntry entry) async {
    final payload = entry.payload;
    await _remote.reorderAllAssessments(
      classId: payload['class_id'] as String,
      assessmentIds: (payload['assessment_ids'] as List<dynamic>)
          .cast<String>(),
      idempotencyKey: entry.id,
    );

    // Mark all reordered assessments as synced.
    final db = await _localDatabase.database;
    final assessmentIds =
        (payload['assessment_ids'] as List<dynamic>).cast<String>();
    for (final id in assessmentIds) {
      await db.update(
        DbTables.assessments,
        {CommonCols.syncStatus: SyncStatus.synced.dbValue},
        where: '${CommonCols.id} = ?',
        whereArgs: [id],
      );
    }
    return const SyncResult.success();
  }
}
