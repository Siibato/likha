import 'package:likha/core/database/db_schema.dart';
import 'package:likha/core/database/local_database.dart';
import 'package:likha/core/errors/exceptions.dart';
import 'package:likha/core/sync/sync_queue.dart';
import 'package:likha/data/models/setup/school_settings_model.dart';
import 'package:sqflite_sqlcipher/sqflite.dart';

Future<SchoolSettingsModel> getCachedSchoolSettings(LocalDatabase db) async {
  final database = await db.database;
  final rows = await database.query(
    DbTables.schoolSettings,
    limit: 1,
  );
  if (rows.isEmpty) throw CacheException('School settings not cached');
  return SchoolSettingsModel.fromMap(rows.first);
}

Future<void> cacheSchoolSettings(
  LocalDatabase db,
  SchoolSettingsModel settings,
) async {
  final database = await db.database;
  await database.insert(
    DbTables.schoolSettings,
    settings
        .copyWith(cachedAt: DateTime.now())
        .toMap(),
    conflictAlgorithm: ConflictAlgorithm.replace,
  );
}

Future<void> updateSchoolSettingsLocally(
  LocalDatabase db, {
  required String schoolName,
  required String schoolRegion,
  required String schoolDivision,
  required String schoolYear,
  required String schoolCode,
  SyncStatus syncStatus = SyncStatus.synced,
  Transaction? txn,
}) async {
  final database = await db.database;
  final executor = txn ?? database;
  await executor.insert(
    DbTables.schoolSettings,
    {
      'id': '1',
      SchoolSettingsCols.schoolName: schoolName,
      SchoolSettingsCols.schoolRegion: schoolRegion,
      SchoolSettingsCols.schoolDivision: schoolDivision,
      SchoolSettingsCols.schoolYear: schoolYear,
      SchoolSettingsCols.schoolCode: schoolCode,
      CommonCols.cachedAt: DateTime.now().toIso8601String(),
      CommonCols.syncStatus: syncStatus.dbValue,
    },
    conflictAlgorithm: ConflictAlgorithm.replace,
  );
}
