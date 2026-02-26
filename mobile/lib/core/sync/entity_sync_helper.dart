import 'package:likha/core/database/local_database.dart';
import 'package:likha/core/sync/change_log_applier.dart';
import 'package:likha/core/sync/change_log_remote_datasource.dart';

/// Helper service to sync individual entities by timestamp
class EntitySyncHelper {
  final LocalDatabase _localDatabase;
  final ChangeLogRemoteDataSource _changeLogRemoteDataSource;
  final ChangeLogApplier _changeLogApplier;

  EntitySyncHelper({
    required LocalDatabase localDatabase,
    required ChangeLogRemoteDataSource changeLogRemoteDataSource,
    required ChangeLogApplier changeLogApplier,
  })  : _localDatabase = localDatabase,
        _changeLogRemoteDataSource = changeLogRemoteDataSource,
        _changeLogApplier = changeLogApplier;

  /// Sync a single entity by comparing timestamps
  /// Returns true if entity was updated, false if already synced
  Future<bool> syncEntityByTimestamp({
    required String entityType,
    required String entityId,
    required String remoteUpdatedAt,
    required String? localSyncedAt,
  }) async {
    try {
      // If local synced_at equals remote updated_at, no need to sync
      if (localSyncedAt != null && localSyncedAt == remoteUpdatedAt) {
        return false; // Already synced
      }

      // Fetch changes since local synced timestamp (or all if null)
      final changes = await _changeLogRemoteDataSource.getEntityChanges(
        entityType: entityType,
        entityId: entityId,
        since: localSyncedAt,
      );

      // Apply changes to local DB
      if (changes.isNotEmpty) {
        await _changeLogApplier.applyAll(changes);
      }

      return true; // Was updated
    } catch (e) {
      // Best-effort: if fetch fails, continue with local data
      return false;
    }
  }

  /// Batch sync multiple entities (common use case for lists)
  Future<void> syncEntitiesByTimestamp({
    required String entityType,
    required List<Map<String, dynamic>> remoteEntities,
  }) async {
    try {
      final db = await _localDatabase.database;
      final tableName = _getTableName(entityType);

      for (final remoteEntity in remoteEntities) {
        final entityId = remoteEntity['id'] as String;
        final remoteUpdatedAt = remoteEntity['updated_at'] as String?;

        if (remoteUpdatedAt == null) continue;

        // Get local synced_at
        final localRow = await db.query(
          tableName,
          where: 'id = ?',
          whereArgs: [entityId],
          limit: 1,
        );

        final localSyncedAt = localRow.isNotEmpty
            ? localRow[0]['synced_at'] as String?
            : null;

        // Sync if different
        await syncEntityByTimestamp(
          entityType: entityType,
          entityId: entityId,
          remoteUpdatedAt: remoteUpdatedAt,
          localSyncedAt: localSyncedAt,
        );
      }
    } catch (e) {
      // Best-effort
    }
  }

  String _getTableName(String entityType) {
    const mapping = {
      'class': 'classes',
      'assessment': 'assessments',
      'assignment': 'assignments',
      'assessment_submission': 'assessment_submissions',
      'assignment_submission': 'assignment_submissions',
      'learning_material': 'learning_materials',
    };
    return mapping[entityType] ?? entityType;
  }
}
