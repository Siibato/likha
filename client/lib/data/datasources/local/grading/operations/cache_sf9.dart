import 'dart:convert';

import 'package:sqflite_sqlcipher/sqflite.dart';
import 'package:likha/core/database/db_schema.dart';
import 'package:likha/core/database/local_database.dart';
import 'package:likha/core/errors/exceptions.dart';

Future<void> cacheSf9(
  LocalDatabase localDatabase,
  String classId,
  String studentId,
  Map<String, dynamic> data,
) async {
  try {
    final db = await localDatabase.database;
    await db.insert(
      DbTables.syncMetadata,
      {
        SyncMetadataCols.key: 'sf9:$classId:$studentId',
        SyncMetadataCols.value: jsonEncode(data),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  } catch (e) {
    throw CacheException('Failed to cache SF9: $e');
  }
}
