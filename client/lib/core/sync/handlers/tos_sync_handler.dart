import 'package:likha/core/database/db_schema.dart';
import 'package:likha/core/database/local_database.dart';
import 'package:likha/core/errors/exceptions.dart';
import 'package:likha/core/logging/sync_logger.dart';
import 'package:likha/core/sync/sync_queue.dart';
import 'package:likha/core/sync/sync_result.dart';
import 'package:likha/data/datasources/local/tos/tos_local_datasource.dart';
import 'package:likha/data/datasources/remote/tos/tos_remote_datasource.dart';
import 'package:likha/data/models/tos/tos_model.dart';

/// Sync handler for all TOS-related [SyncQueueEntry] operations.
///
/// Maps [SyncEntityType.tableOfSpecifications] and [SyncEntityType.tosCompetency]
/// + their respective operations to the corresponding [TosRemoteDataSource] calls.
class TosSyncHandler {
  final TosRemoteDataSource _remote;
  final TosLocalDataSource _local;
  final LocalDatabase _localDatabase;
  final SyncLogger _log;

  TosSyncHandler(
    this._remote,
    this._local,
    this._localDatabase,
    this._log,
  );

  Future<SyncResult> handle(SyncQueueEntry entry) async {
    try {
      switch (entry.entityType) {
        case SyncEntityType.tableOfSpecifications:
          return await _handleTos(entry);
        case SyncEntityType.tosCompetency:
          return await _handleCompetency(entry);
        default:
          return SyncResult.permanentFailure(
            'Unsupported TOS entity type: ${entry.entityType}',
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

  Future<void> _reconcileTos(SyncQueueEntry entry, TosModel model) async {
    final localId = entry.payload['id'] as String? ?? model.id;

    if (model.id != localId) {
      _log.log('Reconciling tos ID $localId → ${model.id}');
      final db = await _localDatabase.database;
      await db.update(
        DbTables.tableOfSpecifications,
        {CommonCols.id: model.id},
        where: '${CommonCols.id} = ?',
        whereArgs: [localId],
      );
      // Update any competencies referencing the old tos_id
      await db.update(
        DbTables.tosCompetencies,
        {TosCompetenciesCols.tosId: model.id},
        where: '${TosCompetenciesCols.tosId} = ?',
        whereArgs: [localId],
      );
    }

    await _local.saveTos(model);
  }

  Future<void> _reconcileCompetency(
    SyncQueueEntry entry,
    CompetencyModel model,
  ) async {
    final localId = entry.payload['id'] as String? ?? model.id;

    if (model.id != localId) {
      _log.log('Reconciling competency ID $localId → ${model.id}');
      final db = await _localDatabase.database;
      await db.update(
        DbTables.tosCompetencies,
        {CommonCols.id: model.id},
        where: '${CommonCols.id} = ?',
        whereArgs: [localId],
      );
    }

    await _local.saveCompetency(model);
  }

  // --------------------------------------------------------------------------
  // Table of Specifications
  // --------------------------------------------------------------------------

  Future<SyncResult> _handleTos(SyncQueueEntry entry) async {
    final payload = entry.payload;

    switch (entry.operation) {
      case SyncOperation.create:
        final classId = payload['class_id'] as String;
        final model = await _remote.createTos(
          classId: classId,
          data: payload,
          idempotencyKey: entry.id,
        );
        await _reconcileTos(entry, model);
        return SyncResult.success(serverId: model.id);

      case SyncOperation.update:
        final tosId = payload['id'] as String;
        final model = await _remote.updateTos(
          tosId: tosId,
          data: payload,
          idempotencyKey: entry.id,
        );
        await _reconcileTos(entry, model);
        return const SyncResult.success();

      case SyncOperation.delete:
        final tosId = payload['id'] as String;
        await _remote.deleteTos(
          tosId: tosId,
          idempotencyKey: entry.id,
        );
        await _local.softDeleteTos(tosId);
        return const SyncResult.success();

      default:
        return SyncResult.permanentFailure(
          'Unsupported tableOfSpecifications operation: ${entry.operation}',
        );
    }
  }

  // --------------------------------------------------------------------------
  // Competency
  // --------------------------------------------------------------------------

  Future<SyncResult> _handleCompetency(SyncQueueEntry entry) async {
    final payload = entry.payload;

    switch (entry.operation) {
      case SyncOperation.create:
        final tosId = payload['tos_id'] as String;
        final model = await _remote.addCompetency(
          tosId: tosId,
          data: payload,
          idempotencyKey: entry.id,
        );
        await _reconcileCompetency(entry, model);
        return SyncResult.success(serverId: model.id);

      case SyncOperation.update:
        final competencyId = payload['id'] as String;
        final model = await _remote.updateCompetency(
          competencyId: competencyId,
          data: payload,
          idempotencyKey: entry.id,
        );
        await _reconcileCompetency(entry, model);
        return const SyncResult.success();

      case SyncOperation.delete:
        final competencyId = payload['id'] as String;
        await _remote.deleteCompetency(
          competencyId: competencyId,
          idempotencyKey: entry.id,
        );
        await _local.softDeleteCompetency(competencyId);
        return const SyncResult.success();

      default:
        return SyncResult.permanentFailure(
          'Unsupported tosCompetency operation: ${entry.operation}',
        );
    }
  }
}
