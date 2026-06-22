import 'dart:convert';

import 'package:sqflite_sqlcipher/sqflite.dart';
import 'package:likha/core/database/db_schema.dart';
import 'package:likha/core/database/local_database.dart';
import 'package:likha/core/errors/exceptions.dart';

Future<void> cacheGradeSummary(
  LocalDatabase localDatabase,
  String classId,
  int termNumber,
  List<Map<String, dynamic>> summary,
) async {
  try {
    final db = await localDatabase.database;
    await db.insert(
      DbTables.syncMetadata,
      {
        SyncMetadataCols.key: 'grade_summary:$classId:$termNumber',
        SyncMetadataCols.value: jsonEncode(summary),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  } catch (e) {
    throw CacheException('Failed to cache grade summary: $e');
  }
}
