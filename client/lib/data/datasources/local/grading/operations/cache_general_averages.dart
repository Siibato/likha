import 'dart:convert';

import 'package:sqflite_sqlcipher/sqflite.dart';
import 'package:likha/core/database/db_schema.dart';
import 'package:likha/core/database/local_database.dart';
import 'package:likha/core/errors/exceptions.dart';

Future<void> cacheGeneralAverages(
  LocalDatabase localDatabase,
  String classId,
  Map<String, dynamic> data,
) async {
  try {
    final db = await localDatabase.database;
    await db.insert(
      DbTables.syncMetadata,
      {
        SyncMetadataCols.key: 'general_averages:$classId',
        SyncMetadataCols.value: jsonEncode(data),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  } catch (e) {
    throw CacheException('Failed to cache general averages: $e');
  }
}
