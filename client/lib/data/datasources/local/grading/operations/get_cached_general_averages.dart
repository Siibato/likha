import 'dart:convert';

import 'package:likha/core/database/db_schema.dart';
import 'package:likha/core/database/local_database.dart';
import 'package:likha/core/errors/exceptions.dart';

Future<Map<String, dynamic>> getCachedGeneralAverages(
  LocalDatabase localDatabase,
  String classId,
) async {
  try {
    final db = await localDatabase.database;
    final result = await db.query(
      DbTables.syncMetadata,
      columns: [SyncMetadataCols.value],
      where: '${SyncMetadataCols.key} = ?',
      whereArgs: ['general_averages:$classId'],
    );
    if (result.isEmpty) {
      throw CacheException('General averages not found in cache');
    }
    final value = result.first[SyncMetadataCols.value] as String;
    final decoded = jsonDecode(value) as Map<String, dynamic>;
    return decoded;
  } on CacheException {
    rethrow;
  } catch (e) {
    throw CacheException('Failed to read cached general averages: $e');
  }
}
