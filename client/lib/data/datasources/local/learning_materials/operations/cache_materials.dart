import 'package:sqflite_sqlcipher/sqflite.dart';

import 'package:likha/core/database/local_database.dart';
import 'package:likha/core/errors/exceptions.dart';
import 'package:likha/core/sync/sync_queue.dart';
import 'package:likha/data/models/learning_materials/learning_material_model.dart';

Future<void> cacheMaterials(
  LocalDatabase localDatabase,
  List<LearningMaterialModel> materials, {
  Transaction? txn,
}) async {
  try {
    final executor = txn ?? await localDatabase.database;
    for (final material in materials) {
      final map = material.toMap();
      map['cached_at'] = DateTime.now().toIso8601String();
      map['sync_status'] = SyncStatus.synced.dbValue;
      // Manual UPSERT: UPDATE first, INSERT if rowsUpdated == 0
      final rowsUpdated = await executor.update(
        'learning_materials',
        map,
        where: 'id = ?',
        whereArgs: [map['id']],
      );
      if (rowsUpdated == 0) {
        await executor.insert(
          'learning_materials',
          map,
          conflictAlgorithm: ConflictAlgorithm.ignore,
        );
      }
    }
  } catch (e) {
    throw CacheException('Failed to cache materials: $e');
  }
}
