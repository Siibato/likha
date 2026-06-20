import 'dart:convert';

import 'package:sqflite_sqlcipher/sqflite.dart';
import 'package:likha/core/database/db_schema.dart';
import 'package:likha/core/database/local_database.dart';
import 'package:likha/core/errors/exceptions.dart';

Future<void> cacheFinalGrades(
  LocalDatabase localDatabase,
  String classId,
  List<Map<String, dynamic>> data,
) async {
  try {
    final db = await localDatabase.database;
    await db.insert(
      DbTables.syncMetadata,
      {
        SyncMetadataCols.key: 'final_grades:$classId',
        SyncMetadataCols.value: jsonEncode(data),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  } catch (e) {
    throw CacheException('Failed to cache final grades: $e');
  }
}
