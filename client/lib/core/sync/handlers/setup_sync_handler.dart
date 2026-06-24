import 'package:likha/core/database/db_schema.dart';
import 'package:likha/core/database/local_database.dart';
import 'package:likha/core/errors/exceptions.dart';
import 'package:likha/core/sync/sync_queue.dart';
import 'package:likha/core/sync/sync_result.dart';
import 'package:likha/data/datasources/remote/setup/setup_remote_datasource.dart';

/// Sync handler for all [SyncEntityType.schoolDetails] operations.
class SetupSyncHandler {
  final SetupRemoteDataSource _remote;
  final LocalDatabase _localDatabase;

  SetupSyncHandler(
    this._remote,
    this._localDatabase,
  );

  Future<SyncResult> handle(SyncQueueEntry entry) async {
    try {
      switch (entry.entityType) {
        case SyncEntityType.schoolDetails:
          return await _handleSchoolDetails(entry);
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

  Future<SyncResult> _handleSchoolDetails(SyncQueueEntry entry) async {
    switch (entry.operation) {
      case SyncOperation.update:
        return await _handleUpdate(entry);
      default:
        return SyncResult.permanentFailure(
          'Unsupported school details operation: ${entry.operation}',
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
      final model = await _remote.updateSchoolDetails(
        schoolName: payload['school_name'] as String,
        schoolRegion: payload['school_region'] as String,
        schoolDivision: payload['school_division'] as String,
        schoolYear: payload['school_year'] as String,
        schoolCode: payload['school_code'] as String,
        schoolDistrict: payload['school_district'] as String?,
        schoolHeadName: payload['school_head_name'] as String?,
        schoolHeadPosition: payload['school_head_position'] as String?,
        idempotencyKey: entry.id,
      );

      // Reconcile server response into local DB
      final db = await _localDatabase.database;
      await db.update(
        DbTables.schoolDetails,
        {
          SchoolDetailsCols.schoolName: model.schoolName,
          SchoolDetailsCols.schoolRegion: model.schoolRegion,
          SchoolDetailsCols.schoolDivision: model.schoolDivision,
          SchoolDetailsCols.schoolYear: model.schoolYear,
          SchoolDetailsCols.schoolCode: model.schoolCode,
          SchoolDetailsCols.schoolDistrict: model.schoolDistrict,
          SchoolDetailsCols.schoolHeadName: model.schoolHeadName,
          SchoolDetailsCols.schoolHeadPosition: model.schoolHeadPosition,
          CommonCols.syncStatus: SyncStatus.synced.dbValue,
        },
        where: '${CommonCols.id} = ?',
        whereArgs: ['1'],
      );
    }

    // Mark local row as synced
    final db = await _localDatabase.database;
    await db.update(
      DbTables.schoolDetails,
      {CommonCols.syncStatus: SyncStatus.synced.dbValue},
      where: '${CommonCols.id} = ?',
      whereArgs: ['1'],
    );

    return const SyncResult.success();
  }
}
