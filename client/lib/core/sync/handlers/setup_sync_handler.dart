import 'package:likha/core/database/db_schema.dart';
import 'package:likha/core/database/local_database.dart';
import 'package:likha/core/errors/exceptions.dart';
import 'package:likha/core/events/data_event_bus.dart';
import 'package:likha/core/sync/sync_queue.dart';
import 'package:likha/core/sync/sync_result.dart';
import 'package:likha/data/datasources/remote/setup/setup_remote_datasource.dart';

/// Sync handler for all [SyncEntityType.schoolSettings] operations.
class SetupSyncHandler {
  final SetupRemoteDataSource _remote;
  final LocalDatabase _localDatabase;
  final DataEventBus _dataEventBus;

  SetupSyncHandler(
    this._remote,
    this._localDatabase,
    this._dataEventBus,
  );

  Future<SyncResult> handle(SyncQueueEntry entry) async {
    try {
      switch (entry.entityType) {
        case SyncEntityType.schoolSettings:
          return await _handleSchoolSettings(entry);
        default:
          return SyncResult.permanentFailure(
            'Unsupported setup entity type: ${entry.entityType}',
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

  Future<SyncResult> _handleSchoolSettings(SyncQueueEntry entry) async {
    switch (entry.operation) {
      case SyncOperation.update:
        return await _handleUpdate(entry);
      default:
        return SyncResult.permanentFailure(
          'Unsupported school settings operation: ${entry.operation}',
        );
    }
  }

  Future<SyncResult> _handleUpdate(SyncQueueEntry entry) async {
    final payload = entry.payload;
    final isCodeOnly = payload['_update_code_only'] as bool? ?? false;

    if (isCodeOnly) {
      await _remote.updateSchoolCode(
        schoolCode: payload['school_code'] as String,
        idempotencyKey: entry.id,
      );
    } else {
      final model = await _remote.updateSchoolSettings(
        schoolName: payload['school_name'] as String,
        schoolRegion: payload['school_region'] as String,
        schoolDivision: payload['school_division'] as String,
        schoolYear: payload['school_year'] as String,
        schoolCode: payload['school_code'] as String,
        idempotencyKey: entry.id,
      );

      // Reconcile server response into local DB
      final db = await _localDatabase.database;
      await db.update(
        DbTables.schoolSettings,
        {
          SchoolSettingsCols.schoolName: model.schoolName,
          SchoolSettingsCols.schoolRegion: model.schoolRegion,
          SchoolSettingsCols.schoolDivision: model.schoolDivision,
          SchoolSettingsCols.schoolYear: model.schoolYear,
          SchoolSettingsCols.schoolCode: model.schoolCode,
          CommonCols.syncStatus: SyncStatus.synced.dbValue,
        },
        where: '${CommonCols.id} = ?',
        whereArgs: ['1'],
      );
    }

    // Mark local row as synced
    final db = await _localDatabase.database;
    await db.update(
      DbTables.schoolSettings,
      {CommonCols.syncStatus: SyncStatus.synced.dbValue},
      where: '${CommonCols.id} = ?',
      whereArgs: ['1'],
    );

    _dataEventBus.notifySchoolSettingsChanged();

    return const SyncResult.success();
  }
}
