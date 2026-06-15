import 'package:likha/core/database/db_schema.dart';
import 'package:likha/core/database/local_database.dart';
import 'package:likha/core/errors/exceptions.dart';
import 'package:likha/core/logging/sync_logger.dart';
import 'package:likha/core/sync/sync_queue.dart';
import 'package:likha/core/sync/sync_result.dart';
import 'package:likha/data/datasources/local/grading/grading_local_datasource.dart';
import 'package:likha/data/datasources/remote/grading/grading_remote_datasource.dart';
import 'package:likha/data/models/grading/grade_item_model.dart';

/// Sync handler for all grading-related [SyncQueueEntry] operations.
///
/// Maps [SyncEntityType.gradeConfig], [SyncEntityType.gradeItem], and
/// [SyncEntityType.gradeScore] + their respective operations to the
/// corresponding [GradingRemoteDataSource] calls.
class GradingSyncHandler {
  final GradingRemoteDataSource _remote;
  final GradingLocalDataSource _local;
  final LocalDatabase _localDatabase;
  final SyncLogger _log;

  GradingSyncHandler(
    this._remote,
    this._local,
    this._localDatabase,
    this._log,
  );

  Future<SyncResult> handle(SyncQueueEntry entry) async {
    try {
      switch (entry.entityType) {
        case SyncEntityType.gradeConfig:
          return await _handleGradeConfig(entry);
        case SyncEntityType.gradeItem:
          return await _handleGradeItem(entry);
        case SyncEntityType.gradeScore:
          return await _handleGradeScore(entry);
        default:
          return SyncResult.permanentFailure(
            'Unsupported grading entity type: ${entry.entityType}',
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

  Future<void> _markSynced(String table, String id) async {
    final db = await _localDatabase.database;
    await db.update(
      table,
      {CommonCols.syncStatus: SyncStatus.synced.dbValue},
      where: '${CommonCols.id} = ?',
      whereArgs: [id],
    );
  }

  Future<void> _markGradeScoresSyncedByItem(String gradeItemId) async {
    final db = await _localDatabase.database;
    await db.update(
      DbTables.gradeScores,
      {CommonCols.syncStatus: SyncStatus.synced.dbValue},
      where: '${GradeScoresCols.gradeItemId} = ?',
      whereArgs: [gradeItemId],
    );
  }

  Future<void> _reconcileGradeItem(
    SyncQueueEntry entry,
    GradeItemModel model,
  ) async {
    final localId = entry.payload['id'] as String? ?? model.id;

    if (model.id != localId) {
      _log.log('Reconciling grade_item ID $localId → ${model.id}');
      final db = await _localDatabase.database;
      await db.update(
        DbTables.gradeItems,
        {CommonCols.id: model.id},
        where: '${CommonCols.id} = ?',
        whereArgs: [localId],
      );
      // Update any grade_scores referencing the old grade_item_id
      await db.update(
        DbTables.gradeScores,
        {GradeScoresCols.gradeItemId: model.id},
        where: '${GradeScoresCols.gradeItemId} = ?',
        whereArgs: [localId],
      );
    }

    await _local.saveItem(model);
  }

  // --------------------------------------------------------------------------
  // Grade Config
  // --------------------------------------------------------------------------

  Future<SyncResult> _handleGradeConfig(SyncQueueEntry entry) async {
    final payload = entry.payload;
    final classId = payload['class_id'] as String;

    switch (entry.operation) {
      case SyncOperation.setup:
        await _remote.setupGrading(
          classId: classId,
          data: payload,
          idempotencyKey: entry.id,
        );
        // Mark all configs for this class as synced
        final db = await _localDatabase.database;
        await db.update(
          DbTables.gradeRecord,
          {CommonCols.syncStatus: SyncStatus.synced.dbValue},
          where: '${GradeRecordCols.classId} = ?',
          whereArgs: [classId],
        );
        return const SyncResult.success();

      case SyncOperation.update:
        final configsPayload = payload['configs'] as List<dynamic>?;
        final List<Map<String, dynamic>> configs;
        if (configsPayload != null) {
          configs = configsPayload.cast<Map<String, dynamic>>();
        } else {
          // Fallback for legacy single-config payloads
          configs = [payload];
        }
        await _remote.updateGradingConfig(
          classId: classId,
          configs: configs,
          idempotencyKey: entry.id,
        );
        final db = await _localDatabase.database;
        await db.update(
          DbTables.gradeRecord,
          {CommonCols.syncStatus: SyncStatus.synced.dbValue},
          where: '${GradeRecordCols.classId} = ?',
          whereArgs: [classId],
        );
        return const SyncResult.success();

      default:
        return SyncResult.permanentFailure(
          'Unsupported gradeConfig operation: ${entry.operation}',
        );
    }
  }

  // --------------------------------------------------------------------------
  // Grade Item
  // --------------------------------------------------------------------------

  Future<SyncResult> _handleGradeItem(SyncQueueEntry entry) async {
    final payload = entry.payload;

    switch (entry.operation) {
      case SyncOperation.create:
        final classId = payload['class_id'] as String;
        final model = await _remote.createGradeItem(
          classId: classId,
          data: payload,
          idempotencyKey: entry.id,
        );
        await _reconcileGradeItem(entry, model);
        return SyncResult.success(serverId: model.id);

      case SyncOperation.update:
        final id = payload['id'] as String;
        await _remote.updateGradeItem(
          id: id,
          data: payload,
          idempotencyKey: entry.id,
        );
        await _markSynced(DbTables.gradeItems, id);
        return const SyncResult.success();

      case SyncOperation.delete:
        final id = payload['id'] as String;
        await _remote.deleteGradeItem(
          id: id,
          idempotencyKey: entry.id,
        );
        await _local.softDeleteItem(id);
        return const SyncResult.success();

      default:
        return SyncResult.permanentFailure(
          'Unsupported gradeItem operation: ${entry.operation}',
        );
    }
  }

  // --------------------------------------------------------------------------
  // Grade Score
  // --------------------------------------------------------------------------

  Future<SyncResult> _handleGradeScore(SyncQueueEntry entry) async {
    final payload = entry.payload;

    switch (entry.operation) {
      case SyncOperation.saveScores:
        final gradeItemId = payload['grade_item_id'] as String;
        final scores = (payload['scores'] as List<dynamic>)
            .cast<Map<String, dynamic>>();
        await _remote.saveScores(
          gradeItemId: gradeItemId,
          scores: scores,
          idempotencyKey: entry.id,
        );
        await _markGradeScoresSyncedByItem(gradeItemId);
        return const SyncResult.success();

      case SyncOperation.setOverride:
        final scoreId = payload['score_id'] as String;
        final overrideScore = (payload['override_score'] as num).toDouble();
        await _remote.setScoreOverride(
          scoreId: scoreId,
          overrideScore: overrideScore,
          idempotencyKey: entry.id,
        );
        await _markSynced(DbTables.gradeScores, scoreId);
        return const SyncResult.success();

      case SyncOperation.clearOverride:
        final scoreId = payload['score_id'] as String;
        await _remote.clearScoreOverride(
          scoreId: scoreId,
          idempotencyKey: entry.id,
        );
        await _markSynced(DbTables.gradeScores, scoreId);
        return const SyncResult.success();

      default:
        return SyncResult.permanentFailure(
          'Unsupported gradeScore operation: ${entry.operation}',
        );
    }
  }
}
