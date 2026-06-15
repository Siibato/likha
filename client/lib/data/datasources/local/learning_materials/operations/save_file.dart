import 'package:sqflite_sqlcipher/sqflite.dart';

import 'package:likha/core/database/db_schema.dart';
import 'package:likha/core/database/local_database.dart';
import 'package:likha/data/models/learning_materials/material_file_model.dart';

Future<void> saveFile(
  LocalDatabase localDatabase,
  MaterialFileModel file, {
  Transaction? txn,
}) async {
  final executor = txn ?? await localDatabase.database;
  final map = file.toMap();
  map[CommonCols.syncStatus] = 'pending';
  map[CommonCols.cachedAt] = DateTime.now().toIso8601String();
  await executor.insert(
    DbTables.materialFiles,
    map,
    conflictAlgorithm: ConflictAlgorithm.replace,
  );
}
