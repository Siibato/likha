import 'package:sqflite/sqflite.dart';

import 'package:likha/core/database/local_database.dart';
import 'package:likha/core/errors/exceptions.dart';
import 'package:likha/core/security/encryption_service.dart';
import 'package:likha/data/models/learning_materials/learning_material_model.dart';
import 'package:likha/core/database/db_schema.dart';

Future<void> cacheMaterialsOp(
  LocalDatabase localDatabase,
  EncryptionService enc,
  List<LearningMaterialModel> materials,
) async {
  try {
    final db = await localDatabase.database;
    await db.transaction((txn) async {
      for (final material in materials) {
        final map = material.toMap();
        map['cached_at'] = DateTime.now().toIso8601String();
        map['needs_sync'] = 0;
        map[LearningMaterialsCols.title] = enc.encryptField(map[LearningMaterialsCols.title] as String?);
        map[LearningMaterialsCols.contentText] = enc.encryptField(map[LearningMaterialsCols.contentText] as String?);
        // Manual UPSERT: UPDATE first, INSERT if rowsUpdated == 0
        final rowsUpdated = await txn.update(
          'learning_materials',
          map,
          where: 'id = ?',
          whereArgs: [map['id']],
        );
        if (rowsUpdated == 0) {
          await txn.insert(
            'learning_materials',
            map,
            conflictAlgorithm: ConflictAlgorithm.ignore,
          );
        }
      }
    });
  } catch (e) {
    throw CacheException('Failed to cache materials: $e');
  }
}
