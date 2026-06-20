import 'package:sqflite_sqlcipher/sqflite.dart';

import 'package:likha/core/database/db_schema.dart';
import 'package:likha/core/database/local_database.dart';
import 'package:likha/data/models/learning_materials/learning_material_model.dart';

Future<void> saveMaterial(
  LocalDatabase localDatabase,
  LearningMaterialModel material, {
  Transaction? txn,
}) async {
  final executor = txn ?? await localDatabase.database;
  final map = material.toMap();
  map[CommonCols.syncStatus] = 'pending';
  map[CommonCols.cachedAt] = DateTime.now().toIso8601String();
  await executor.insert(
    DbTables.learningMaterials,
    map,
    conflictAlgorithm: ConflictAlgorithm.replace,
  );
}
