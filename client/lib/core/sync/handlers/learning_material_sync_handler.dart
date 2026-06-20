import 'package:likha/core/database/db_schema.dart';
import 'package:likha/core/database/local_database.dart';
import 'package:likha/core/errors/exceptions.dart';
import 'package:likha/core/logging/sync_logger.dart';
import 'package:likha/core/sync/sync_queue.dart';
import 'package:likha/core/sync/sync_result.dart';
import 'package:likha/data/datasources/local/learning_materials/learning_material_local_datasource.dart';
import 'package:likha/data/datasources/remote/learning_materials/learning_material_remote_datasource.dart';
import 'package:likha/data/models/learning_materials/learning_material_model.dart';

/// Sync handler for all learning-material-related [SyncQueueEntry] operations.
///
/// Maps [SyncEntityType.learningMaterial] and [SyncEntityType.materialFile]
/// + their respective operations to the corresponding
/// [LearningMaterialRemoteDataSource] calls.
class LearningMaterialSyncHandler {
  final LearningMaterialRemoteDataSource _remote;
  final LearningMaterialLocalDataSource _local;
  final LocalDatabase _localDatabase;
  final SyncLogger _log;

  LearningMaterialSyncHandler(
    this._remote,
    this._local,
    this._localDatabase,
    this._log,
  );

  Future<SyncResult> handle(SyncQueueEntry entry) async {
    try {
      switch (entry.entityType) {
        case SyncEntityType.learningMaterial:
          return await _handleLearningMaterial(entry);
        case SyncEntityType.materialFile:
          return await _handleMaterialFile(entry);
        default:
          return SyncResult.permanentFailure(
            'Unsupported learning material entity type: ${entry.entityType}',
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

  Future<void> _reconcileLearningMaterial(
    SyncQueueEntry entry,
    LearningMaterialModel model,
  ) async {
    final localId = entry.payload['id'] as String? ?? model.id;

    if (model.id != localId) {
      _log.log('Reconciling learning_material ID $localId → ${model.id}');
      final db = await _localDatabase.database;
      await db.update(
        DbTables.learningMaterials,
        {CommonCols.id: model.id},
        where: '${CommonCols.id} = ?',
        whereArgs: [localId],
      );
      // Update any material_files referencing the old material_id
      await db.update(
        DbTables.materialFiles,
        {MaterialFilesCols.materialId: model.id},
        where: '${MaterialFilesCols.materialId} = ?',
        whereArgs: [localId],
      );
    }

    await _local.saveMaterial(model);
  }

  // --------------------------------------------------------------------------
  // Learning Material
  // --------------------------------------------------------------------------

  Future<SyncResult> _handleLearningMaterial(SyncQueueEntry entry) async {
    final payload = entry.payload;

    switch (entry.operation) {
      case SyncOperation.create:
        final classId = payload['class_id'] as String;
        final model = await _remote.createMaterial(
          classId: classId,
          data: payload,
          idempotencyKey: entry.id,
        );
        await _reconcileLearningMaterial(entry, model);
        return SyncResult.success(serverId: model.id);

      case SyncOperation.update:
        final id = payload['id'] as String;
        final model = await _remote.updateMaterial(
          materialId: id,
          data: payload,
          idempotencyKey: entry.id,
        );
        await _reconcileLearningMaterial(entry, model);
        return const SyncResult.success();

      case SyncOperation.delete:
        final id = payload['id'] as String;
        await _remote.deleteMaterial(
          materialId: id,
          idempotencyKey: entry.id,
        );
        await _local.softDeleteMaterial(id);
        return const SyncResult.success();

      case SyncOperation.reorder:
        final classId = payload['class_id'] as String;
        final materialIds =
            (payload['material_ids'] as List<dynamic>).cast<String>();
        await _remote.reorderAllMaterials(
          classId: classId,
          materialIds: materialIds,
          idempotencyKey: entry.id,
        );
        // Mark all reordered materials as synced
        final db = await _localDatabase.database;
        for (final materialId in materialIds) {
          await db.update(
            DbTables.learningMaterials,
            {CommonCols.syncStatus: SyncStatus.synced.dbValue},
            where: '${CommonCols.id} = ?',
            whereArgs: [materialId],
          );
        }
        return const SyncResult.success();

      default:
        return SyncResult.permanentFailure(
          'Unsupported learningMaterial operation: ${entry.operation}',
        );
    }
  }

  // --------------------------------------------------------------------------
  // Material File
  // --------------------------------------------------------------------------

  Future<SyncResult> _handleMaterialFile(SyncQueueEntry entry) async {
    final payload = entry.payload;

    switch (entry.operation) {
      case SyncOperation.delete:
        final fileId = payload['file_id'] as String? ?? payload['id'] as String;
        await _remote.deleteFile(
          fileId: fileId,
          idempotencyKey: entry.id,
        );
        await _local.softDeleteFile(fileId);
        return const SyncResult.success();

      default:
        return SyncResult.permanentFailure(
          'Unsupported materialFile operation: ${entry.operation}',
        );
    }
  }
}
