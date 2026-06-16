import 'package:likha/core/database/db_schema.dart';
import 'package:likha/core/database/local_database.dart';
import 'package:likha/core/errors/exceptions.dart';
import 'package:likha/core/events/data_event_bus.dart';
import 'package:likha/core/logging/sync_logger.dart';
import 'package:likha/core/sync/sync_queue.dart';
import 'package:likha/core/sync/sync_result.dart';
import 'package:likha/data/datasources/local/assignments/assignment_local_datasource.dart';
import 'package:likha/data/datasources/remote/assignments/assignment_remote_datasource.dart';
import 'package:likha/data/models/assignments/assignment_model.dart';

/// Sync handler for all [SyncEntityType.assignment] and
/// [SyncEntityType.assignmentSubmission] operations.
///
/// Invoked by the outbound sync engine for each pending assignment queue entry.
/// Sends the entry ID as `Idempotency-Key`, calls the corresponding remote
/// datasource method, and reconciles the server response into the local DB
/// with conflict resolution.
class AssignmentSyncHandler {
  final AssignmentRemoteDataSource _remote;
  final AssignmentLocalDataSource _local;
  final LocalDatabase _localDatabase;
  final SyncLogger _log;
  final DataEventBus _dataEventBus;

  AssignmentSyncHandler(
    this._remote,
    this._local,
    this._localDatabase,
    this._log,
    this._dataEventBus,
  );

  Future<SyncResult> handle(SyncQueueEntry entry) async {
    try {
      switch (entry.entityType) {
        case SyncEntityType.assignment:
          return await _handleAssignment(entry);
        case SyncEntityType.assignmentSubmission:
          return await _handleAssignmentSubmission(entry);
        default:
          return SyncResult.permanentFailure(
            'Unsupported assignment entity type: ${entry.entityType}',
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

  /// Reconciles a server-returned [AssignmentModel] into the local DB.
  /// If the local row was modified after [entry.createdAt], data fields are
  /// **not** overwritten so newer local changes are preserved.
  Future<void> _reconcileAssignment(
    SyncQueueEntry entry,
    AssignmentModel model,
  ) async {
    final localId = entry.payload['id'] as String? ?? model.id;

    // ID reconciliation: server may return a different ID for creates.
    if (model.id != localId) {
      final db = await _localDatabase.database;
      await db.update(
        DbTables.assignments,
        {CommonCols.id: model.id},
        where: '${CommonCols.id} = ?',
        whereArgs: [localId],
      );
    }

    final conflict = await _isLocalModifiedAfter(
      DbTables.assignments,
      model.id,
      entry.createdAt,
    );

    if (!conflict) {
      await _local.cacheAssignmentDetail(model);
    } else {
      _log.warn(
        'Conflict detected for assignment ${model.id}; '
        'skipping overwrite to preserve newer local changes.',
      );
      // Still mark as synced since the server processed the request.
      final db = await _localDatabase.database;
      await db.update(
        DbTables.assignments,
        {CommonCols.syncStatus: SyncStatus.synced.dbValue},
        where: '${CommonCols.id} = ?',
        whereArgs: [model.id],
      );
    }
  }

  // --------------------------------------------------------------------------
  // Assignment entity handlers
  // --------------------------------------------------------------------------

  Future<SyncResult> _handleAssignment(SyncQueueEntry entry) async {
    switch (entry.operation) {
      case SyncOperation.create:
        return await _handleAssignmentCreate(entry);
      case SyncOperation.update:
        return await _handleAssignmentUpdate(entry);
      case SyncOperation.delete:
        return await _handleAssignmentDelete(entry);
      case SyncOperation.unpublish:
        return await _handleAssignmentUnpublish(entry);
      default:
        return SyncResult.permanentFailure(
          'Unsupported assignment operation: ${entry.operation}',
        );
    }
  }

  Future<SyncResult> _handleAssignmentCreate(SyncQueueEntry entry) async {
    final payload = entry.payload;
    final classId = payload['class_id'] as String;
    final model = await _remote.createAssignment(
      classId: classId,
      data: payload,
      idempotencyKey: entry.id,
    );
    await _reconcileAssignment(entry, model);
    return SyncResult.success(serverId: model.id);
  }

  Future<SyncResult> _handleAssignmentUpdate(SyncQueueEntry entry) async {
    final payload = entry.payload;

    // Dispatch by payload shape: reorder, publish, or regular update.
    final assignmentIds = payload['assignment_ids'] as List<dynamic>?;
    final action = payload['action'] as String?;

    if (assignmentIds != null) {
      return await _handleAssignmentReorder(entry);
    }

    if (action == 'publish') {
      return await _handleAssignmentPublish(entry);
    }

    // Regular update
    final assignmentId = payload['id'] as String;
    final model = await _remote.updateAssignment(
      assignmentId: assignmentId,
      data: payload,
      idempotencyKey: entry.id,
    );
    await _reconcileAssignment(entry, model);
    return const SyncResult.success();
  }

  Future<SyncResult> _handleAssignmentDelete(SyncQueueEntry entry) async {
    final assignmentId = entry.payload['id'] as String;
    await _remote.deleteAssignment(
      assignmentId: assignmentId,
      idempotencyKey: entry.id,
    );
    await _local.deleteAssignment(assignmentId: assignmentId);
    return const SyncResult.success();
  }

  Future<SyncResult> _handleAssignmentPublish(SyncQueueEntry entry) async {
    final assignmentId = entry.payload['id'] as String;
    final model = await _remote.publishAssignment(
      assignmentId: assignmentId,
      idempotencyKey: entry.id,
    );
    await _reconcileAssignment(entry, model);
    return const SyncResult.success();
  }

  Future<SyncResult> _handleAssignmentUnpublish(SyncQueueEntry entry) async {
    final assignmentId = entry.payload['id'] as String;
    final model = await _remote.unpublishAssignment(
      assignmentId: assignmentId,
      idempotencyKey: entry.id,
    );
    await _reconcileAssignment(entry, model);
    return const SyncResult.success();
  }

  Future<SyncResult> _handleAssignmentReorder(SyncQueueEntry entry) async {
    final payload = entry.payload;
    await _remote.reorderAllAssignments(
      classId: payload['class_id'] as String,
      assignmentIds: (payload['assignment_ids'] as List<dynamic>)
          .cast<String>(),
      idempotencyKey: entry.id,
    );

    // Mark all reordered assignments as synced.
    final db = await _localDatabase.database;
    final assignmentIds =
        (payload['assignment_ids'] as List<dynamic>).cast<String>();
    for (final id in assignmentIds) {
      await db.update(
        DbTables.assignments,
        {CommonCols.syncStatus: SyncStatus.synced.dbValue},
        where: '${CommonCols.id} = ?',
        whereArgs: [id],
      );
    }
    return const SyncResult.success();
  }

  // --------------------------------------------------------------------------
  // AssignmentSubmission entity handlers
  // --------------------------------------------------------------------------

  Future<SyncResult> _handleAssignmentSubmission(SyncQueueEntry entry) async {
    switch (entry.operation) {
      case SyncOperation.submit:
        return await _handleSubmissionSubmit(entry);
      case SyncOperation.grade:
        return await _handleSubmissionGrade(entry);
      case SyncOperation.update:
        return await _handleSubmissionUpdate(entry);
      default:
        return SyncResult.permanentFailure(
          'Unsupported assignmentSubmission operation: ${entry.operation}',
        );
    }
  }

  Future<SyncResult> _handleSubmissionSubmit(SyncQueueEntry entry) async {
    final payload = entry.payload;
    final submissionId = payload['submission_id'] as String;
    final model = await _remote.submitAssignment(
      submissionId: submissionId,
      idempotencyKey: entry.id,
    );
    await _local.cacheSubmissionDetail(model);
    return const SyncResult.success();
  }

  Future<SyncResult> _handleSubmissionGrade(SyncQueueEntry entry) async {
    final payload = entry.payload;
    final submissionId = payload['id'] as String;
    final model = await _remote.gradeSubmission(
      submissionId: submissionId,
      data: {
        'score': payload['score'],
        if (payload['feedback'] != null) 'feedback': payload['feedback'],
      },
      idempotencyKey: entry.id,
    );
    await _local.cacheSubmissionDetail(model);
    final db = await _localDatabase.database;
    final assignmentRows = await db.query(
      DbTables.assignments,
      columns: [AssignmentsCols.classId],
      where: '${CommonCols.id} = ?',
      whereArgs: [model.assignmentId],
      limit: 1,
    );
    if (assignmentRows.isNotEmpty) {
      final classId = assignmentRows.first[AssignmentsCols.classId] as String?;
      if (classId != null && classId.isNotEmpty) {
        _dataEventBus.notifyGradesChanged(classId);
      }
    }
    return const SyncResult.success();
  }

  Future<SyncResult> _handleSubmissionUpdate(SyncQueueEntry entry) async {
    final payload = entry.payload;
    final action = payload['action'] as String?;

    if (action == 'return') {
      final submissionId = payload['id'] as String;
      final model = await _remote.returnSubmission(
        submissionId: submissionId,
        idempotencyKey: entry.id,
      );
      await _local.cacheSubmissionDetail(model);
      return const SyncResult.success();
    }

    return SyncResult.permanentFailure(
      'Unsupported assignmentSubmission update action: $action',
    );
  }
}
