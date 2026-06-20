import 'dart:convert';

import 'package:likha/core/database/db_schema.dart';
import 'package:likha/core/database/local_database.dart';
import 'package:likha/core/errors/exceptions.dart';

Future<List<Map<String, dynamic>>> getCachedGradeSummary(
  LocalDatabase localDatabase,
  String classId,
  int gradingPeriodNumber,
) async {
  try {
    final db = await localDatabase.database;
    final result = await db.query(
      DbTables.syncMetadata,
      columns: [SyncMetadataCols.value],
      where: '${SyncMetadataCols.key} = ?',
      whereArgs: ['grade_summary:$classId:$gradingPeriodNumber'],
    );
    if (result.isEmpty) {
      throw CacheException('Grade summary not found in cache');
    }
    final value = result.first[SyncMetadataCols.value] as String;
    final decoded = jsonDecode(value) as List<dynamic>;
    return decoded.cast<Map<String, dynamic>>();
  } on CacheException {
    rethrow;
  } catch (e) {
    throw CacheException('Failed to read cached grade summary: $e');
  }
}
