import 'dart:convert';

import 'package:likha/core/database/db_schema.dart';
import 'package:likha/core/database/local_database.dart';
import 'package:likha/core/errors/exceptions.dart';

Future<List<Map<String, dynamic>>> getCachedFinalGrades(
  LocalDatabase localDatabase,
  String classId,
) async {
  try {
    final db = await localDatabase.database;
    final result = await db.query(
      DbTables.syncMetadata,
      columns: [SyncMetadataCols.value],
      where: '${SyncMetadataCols.key} = ?',
      whereArgs: ['final_grades:$classId'],
    );
    if (result.isEmpty) {
      throw CacheException('Final grades not found in cache');
    }
    final value = result.first[SyncMetadataCols.value] as String;
    final decoded = jsonDecode(value) as List<dynamic>;
    return decoded.cast<Map<String, dynamic>>();
  } on CacheException {
    rethrow;
  } catch (e) {
    throw CacheException('Failed to read cached final grades: $e');
  }
}
