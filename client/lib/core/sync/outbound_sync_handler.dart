import 'dart:io';
import 'package:likha/core/database/db_schema.dart';
import 'package:likha/core/database/local_database.dart';
import 'package:likha/core/sync/sync_logger.dart';
import 'package:likha/core/sync/sync_queue.dart';
import 'package:likha/core/sync/sync_state.dart';
import 'package:likha/data/datasources/remote/sync_remote_datasource.dart';
import 'package:likha/data/models/sync/push_response_model.dart';

class OutboundSyncHandler {
  final SyncQueue _syncQueue;
  final SyncRemoteDataSource _syncRemoteDataSource;
  final LocalDatabase _localDatabase;
  final SyncLogger _log;
  final SyncStateUpdater _updateState;

  OutboundSyncHandler(
    this._syncQueue,
    this._syncRemoteDataSource,
    this._localDatabase,
    this._log,
    this._updateState,
  );

  Future<void> outboundSync() async {
    _log.log('outboundSync() - START');
    
    final pending = await _syncQueue.getAllRetriable();
    _log.log('Found ${pending.length} pending operations');
    
    if (pending.isEmpty) {
      _log.log('No pending operations, returning');
      return;
    }
    
    // Log all pending operations for debugging
    for (final op in pending) {
      _log.log('Pending op: ${op.entityType}.${op.operation} (${op.id}) - status: ${op.status}');
    }

    // PASS 0: Process assessmentSubmission creates FIRST so dependent ops
    // (submit) can reference the real server-assigned ID.
    final assessmentSubmissionCreates = pending
        .where((e) =>
            e.entityType == SyncEntityType.assessmentSubmission &&
            e.operation == SyncOperation.create)
        .toList();

    if (assessmentSubmissionCreates.isNotEmpty) {
      await syncAssessmentSubmissionCreates(assessmentSubmissionCreates);
    }

    // Re-fetch after reconciliation — creates are now 'succeeded',
    // remaining pending entries have updated submission_ids in their payloads.
    var remaining = await _syncQueue.getAllRetriable();
    if (remaining.isEmpty) return;

    // PASS 1: Process assignmentSubmission creates so dependent ops
    // (submit, file uploads) can reference the real server-assigned ID.
    final assignmentSubmissionCreates = remaining
        .where((e) =>
            e.entityType == SyncEntityType.assignmentSubmission &&
            e.operation == SyncOperation.create)
        .toList();

    if (assignmentSubmissionCreates.isNotEmpty) {
      await syncAssignmentSubmissionCreates(assignmentSubmissionCreates);
    }

    // Re-fetch after reconciliation — creates are now 'succeeded',
    // remaining pending entries have updated submission_ids in their payloads.
    remaining = await _syncQueue.getAllRetriable();
    if (remaining.isEmpty) return;

    // Existing bucket-based logic (unchanged):
    final nonMaterialFileUploads = remaining
        .where((e) => e.operation == SyncOperation.upload &&
                    e.entityType != SyncEntityType.materialFile)
        .toList();
    final materialFileUploads = remaining
        .where((e) => e.operation == SyncOperation.upload &&
                    e.entityType == SyncEntityType.materialFile)
        .toList();
    final regularOps = remaining
        .where((e) => e.operation != SyncOperation.upload)
        .toList();

    _log.log('Found ${regularOps.length} regular operations');
    
    final opsByType = <String, int>{};
    for (final op in regularOps) {
      opsByType[op.entityType.serverValue] = (opsByType[op.entityType.serverValue] ?? 0) + 1;
      if (op.entityType == SyncEntityType.gradeScore) {
        _log.log('Grade score operation: ${op.operation} (${op.id})');
      }
    }

    _log.log('Operations by type: $opsByType');

    _log.pushStarting(
      uploadOpsCount: nonMaterialFileUploads.length + materialFileUploads.length,
      regularOpsCount: regularOps.length,
      operationsByType: opsByType,
    );

    final pushStartTime = DateTime.now();

    // Step 1: Run non-material file uploads first (submission files, etc.)
    for (final op in nonMaterialFileUploads) {
      await handleFileUpload(op);
    }

    // Step 2: Run all regular operations in one batch
    if (regularOps.isNotEmpty) {
      await syncRegularBatch(regularOps, pushStartTime);
    }

    // Step 3: Run material file uploads AFTER regular ops (material now exists on server)
    for (final op in materialFileUploads) {
      await handleFileUpload(op);
    }
  }

  /// Process assessmentSubmission creates first and reconcile local IDs with server IDs
  Future<void> syncAssessmentSubmissionCreates(
      List<SyncQueueEntry> createOps) async {
    final operations = createOps.map((entry) => {
      'id':          entry.id,
      'entity_type': entry.entityType.serverValue,
      'operation':   entry.operation.serverValue,
      'payload':     entry.payload,
    }).toList();

    final response =
        await _syncRemoteDataSource.pushOperations(operations: operations);

    final db = await _localDatabase.database;

    for (final result in response.results) {
      if (result.success) {
        final entry = createOps.firstWhere((e) => e.id == result.id);
        final localId = entry.payload['id'] as String?;
        final serverId = result.serverId;

        if (localId != null && serverId != null && localId != serverId) {
          // Reconcile assessment_submissions table
          await db.update(
            DbTables.assessmentSubmissions,
            {CommonCols.id: serverId},
            where: '${CommonCols.id} = ?',
            whereArgs: [localId],
          );

          // Rewrite submission_id in all remaining pending queue entries
          // (covers submit op + save_answers op referencing the local UUID)
          await _syncQueue.updatePendingSubmissionIds(localId, serverId);
        }

        await _syncQueue.markSucceeded(result.id);
      } else {
        await _syncQueue.markFailed(result.id, result.error ?? 'Unknown error');
      }
    }
  }

  /// Process assignmentSubmission creates first and reconcile local IDs with server IDs
  Future<void> syncAssignmentSubmissionCreates(
      List<SyncQueueEntry> createOps) async {
    final operations = createOps.map((entry) => {
      'id':          entry.id,
      'entity_type': entry.entityType.serverValue,
      'operation':   entry.operation.serverValue,
      'payload':     entry.payload,
    }).toList();

    final response =
        await _syncRemoteDataSource.pushOperations(operations: operations);

    final db = await _localDatabase.database;

    for (final result in response.results) {
      if (result.success) {
        final entry = createOps.firstWhere((e) => e.id == result.id);
        final localId = entry.payload['id'] as String?;
        final serverId = result.serverId;

        if (localId != null && serverId != null && localId != serverId) {
          // Reconcile assignment_submissions table
          await db.update(
            DbTables.assignmentSubmissions,
            {CommonCols.id: serverId},
            where: '${CommonCols.id} = ?',
            whereArgs: [localId],
          );

          // Reconcile submission_files staged under the local submission ID
          await db.update(
            DbTables.submissionFiles,
            {SubmissionFilesCols.submissionId: serverId},
            where: '${SubmissionFilesCols.submissionId} = ? AND ${CommonCols.needsSync} = 1',
            whereArgs: [localId],
          );

          // Rewrite submission_id in all remaining pending queue entries
          // (covers submit op + file upload ops referencing the local UUID)
          await _syncQueue.updatePendingSubmissionIds(localId, serverId);
        }

        await _syncQueue.markSucceeded(result.id);
      } else {
        await _syncQueue.markFailed(result.id, result.error ?? 'Unknown error');
      }
    }
  }

  /// Sync a batch of operations
  Future<void> syncRegularBatch(List<SyncQueueEntry> regularOps, DateTime pushStartTime) async {
    _updateState(pendingCount: regularOps.length);

    final operations = regularOps.map((entry) {
      return {
        'id':          entry.id,
        'entity_type': entry.entityType.serverValue,
        'operation':   entry.operation.serverValue,
        'payload':     entry.payload,
      };
    }).toList();

    final response = await _syncRemoteDataSource.pushOperations(
      operations: operations,
    );

    await processPushResults(response, pushStartTime);
  }

  /// Process push results and update local state
  Future<void> processPushResults(PushResponseModel response, DateTime startTime) async {
    final db = await _localDatabase.database;

    // Track success/failure by entity type for logging
    final successByType = <String, int>{};
    final failedByType = <String, int>{};

    for (final result in response.results) {
      final opId = result.id;
      final success = result.success;
      final serverId = result.serverId;
      final entityType = result.entityType;
      final operation = result.operation;

      // Log individual operation result
      _log.pushOperationResult(
        entityType: entityType,
        operation: operation,
        opId: opId,
        success: success,
        serverId: serverId,
        error: result.error,
      );

      if (success) {
        successByType[entityType] = (successByType[entityType] ?? 0) + 1;

        // Fetch entry BEFORE marking succeeded (entry is hard-deleted on succeed)
        final entry = await _syncQueue.getById(opId);

        // Minimal fallback: if server returned a different ID (class dedup edge case only),
        // update the local database to use the server's ID instead
        if (serverId != null && operation == 'create' && entry != null) {
          final payloadId = entry.payload['id'] as String?;
          if (payloadId != null && payloadId != serverId) {
            // Server returned different ID (likely due to class title dedup)
            // Update the entity table to use the server ID
            if (entityType == SyncEntityType.classEntity.serverValue) {
              await db.update(
                DbTables.classes,
                {CommonCols.id: serverId},
                where: '${CommonCols.id} = ?',
                whereArgs: [payloadId],
              );
            } else if (entityType == SyncEntityType.gradeItem.serverValue) {
              // Reconcile grade_item ID
              await db.update(
                DbTables.gradeItems,
                {CommonCols.id: serverId},
                where: '${CommonCols.id} = ?',
                whereArgs: [payloadId],
              );
              // Update any grade_scores referencing the old grade_item_id
              await db.update(
                DbTables.gradeScores,
                {GradeScoresCols.gradeItemId: serverId},
                where: '${GradeScoresCols.gradeItemId} = ?',
                whereArgs: [payloadId],
              );
            }
          }
        }

        // Mark as succeeded and remove from queue
        await _syncQueue.markSucceeded(opId);
      } else {
        failedByType[entityType] = (failedByType[entityType] ?? 0) + 1;

        // Mark as failed
        final error = result.error ?? 'Unknown error';
        await _syncQueue.markFailed(opId, error);
      }
    }

    // Log summary of push results
    final duration = DateTime.now().difference(startTime).inMilliseconds;
    _log.pushResults(
      successByType: successByType,
      failedByType: failedByType,
      idMappingsByType: const {},
      totalDuration: duration,
    );
  }

  /// Handles a single file upload operation by calling the multipart endpoint directly.
  /// References pattern in: mobile/lib/data/datasources/remote/assignment_remote_datasource.dart
  /// For material files, looks up correct (reconciled) material_id from DB instead of using payload.
  Future<void> handleFileUpload(SyncQueueEntry op) async {
    try {
      final payload      = op.payload;
      final localPath    = payload['local_path']    as String;
      final fileName     = payload['file_name']     as String;
      final fileId       = payload['file_id']       as String?;
      final submissionId = payload['submission_id'] as String?;
      var materialId     = payload['material_id']   as String?;

      // For material file uploads, look up the correct (reconciled) material_id from DB
      if (materialId != null && fileId != null) {
        try {
          final db = await _localDatabase.database;
          final rows = await db.query(
            DbTables.materialFiles,
            columns: [MaterialFilesCols.materialId],
            where: '${CommonCols.id} = ?',
            whereArgs: [fileId],
          );
          if (rows.isNotEmpty) {
            materialId = rows.first[MaterialFilesCols.materialId] as String?;
          }
        } catch (_) {
          // If DB lookup fails, fall back to payload value
        }
      }

      if (submissionId != null) {
        final response = await _syncRemoteDataSource.uploadSubmissionFile(
          submissionId: submissionId,
          localPath: localPath,
          fileName: fileName,
        );

        // Fix 3: Reconcile server file ID with local UUID
        if (response != null && fileId != null) {
          final serverId = response['id'] as String?;
          if (serverId != null && serverId != fileId) {
            try {
              final db = await _localDatabase.database;
              // Rename row ID from local UUID to server UUID
              await db.update(
                DbTables.submissionFiles,
                {
                  CommonCols.id: serverId,
                  SubmissionFilesCols.localPath: '',
                },
                where: '${CommonCols.id} = ?',
                whereArgs: [fileId],
              );
            } catch (e) {
              _log.error('Failed to reconcile file ID: $e');
              // Continue — file is on server even if local reconciliation fails
            }
          }
        }
      } else if (materialId != null) {
        await _syncRemoteDataSource.uploadMaterialFile(
          materialId: materialId,
          localPath: localPath,
          fileName: fileName,
        );
      }

      // Clean up staged file after successful upload
      try {
        final stagedFile = File(localPath);
        if (await stagedFile.exists()) {
          await stagedFile.delete();
        }
      } catch (_) {
        // Log but don't fail sync if cleanup fails
      }

      await _syncQueue.markSucceeded(op.id);
    } catch (e) {
      await _syncQueue.markFailed(op.id, e.toString());
    }
  }
}
