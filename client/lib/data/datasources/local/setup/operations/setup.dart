import 'package:likha/core/database/db_schema.dart';
import 'package:likha/core/database/local_database.dart';
import 'package:likha/core/errors/exceptions.dart';
import 'package:likha/core/sync/sync_queue.dart';
import 'package:likha/data/models/setup/school_details_model.dart';
import 'package:sqflite_sqlcipher/sqflite.dart';

Future<SchoolDetailsModel> getCachedSchoolDetails(LocalDatabase db) async {
  final database = await db.database;
  final rows = await database.query(
    DbTables.schoolDetails,
    limit: 1,
  );
  if (rows.isEmpty) throw CacheException('School settings not cached');
  return SchoolDetailsModel.fromMap(rows.first);
}

Future<void> cacheSchoolDetails(
  LocalDatabase db,
  SchoolDetailsModel settings,
) async {
  final database = await db.database;
  await database.insert(
    DbTables.schoolDetails,
    settings
        .copyWith(cachedAt: DateTime.now())
        .toMap(),
    conflictAlgorithm: ConflictAlgorithm.replace,
  );
}

Future<void> updateSchoolDetailsLocally(
  LocalDatabase db, {
  required String schoolName,
  required String schoolRegion,
  required String schoolDivision,
  required String schoolYear,
  required String schoolCode,
  String? schoolDistrict,
  String? schoolHeadName,
  String? schoolHeadPosition,
  SyncStatus syncStatus = SyncStatus.synced,
  Transaction? txn,
}) async {
  final database = await db.database;
  final executor = txn ?? database;
  await executor.insert(
    DbTables.schoolDetails,
    {
      'id': '1',
      SchoolDetailsCols.schoolName: schoolName,
      SchoolDetailsCols.schoolRegion: schoolRegion,
      SchoolDetailsCols.schoolDivision: schoolDivision,
      SchoolDetailsCols.schoolYear: schoolYear,
      SchoolDetailsCols.schoolCode: schoolCode,
      SchoolDetailsCols.schoolDistrict: schoolDistrict,
      SchoolDetailsCols.schoolHeadName: schoolHeadName,
      SchoolDetailsCols.schoolHeadPosition: schoolHeadPosition,
      CommonCols.cachedAt: DateTime.now().toIso8601String(),
      CommonCols.syncStatus: syncStatus.dbValue,
    },
    conflictAlgorithm: ConflictAlgorithm.replace,
  );
}
