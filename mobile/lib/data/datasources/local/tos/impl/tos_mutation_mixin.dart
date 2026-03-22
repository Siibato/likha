import 'package:sqflite/sqflite.dart';

import 'package:likha/core/database/db_schema.dart';
import 'package:likha/data/models/tos/tos_model.dart';
import '../tos_local_datasource_base.dart';

mixin TosMutationMixin on TosLocalDataSourceBase {
  @override
  Future<void> saveTos(TosModel tos) async {
    final db = await localDatabase.database;
    await db.insert(
      DbTables.tableOfSpecifications,
      {
        ...tos.toMap(),
        CommonCols.needsSync: 1,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<void> updateTosFields(
    String tosId,
    Map<String, dynamic> data,
  ) async {
    final db = await localDatabase.database;
    await db.update(
      DbTables.tableOfSpecifications,
      {
        ...data,
        CommonCols.updatedAt: DateTime.now().toIso8601String(),
        CommonCols.needsSync: 1,
      },
      where: '${CommonCols.id} = ?',
      whereArgs: [tosId],
    );
  }

  @override
  Future<void> softDeleteTos(String tosId) async {
    final db = await localDatabase.database;
    final now = DateTime.now().toIso8601String();
    await db.update(
      DbTables.tableOfSpecifications,
      {
        CommonCols.deletedAt: now,
        CommonCols.updatedAt: now,
        CommonCols.needsSync: 1,
      },
      where: '${CommonCols.id} = ?',
      whereArgs: [tosId],
    );
  }

  @override
  Future<void> saveCompetency(CompetencyModel competency) async {
    final db = await localDatabase.database;
    await db.insert(
      DbTables.tosCompetencies,
      {
        ...competency.toMap(),
        CommonCols.needsSync: 1,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<void> updateCompetencyFields(
    String competencyId,
    Map<String, dynamic> data,
  ) async {
    final db = await localDatabase.database;
    await db.update(
      DbTables.tosCompetencies,
      {
        ...data,
        CommonCols.updatedAt: DateTime.now().toIso8601String(),
        CommonCols.needsSync: 1,
      },
      where: '${CommonCols.id} = ?',
      whereArgs: [competencyId],
    );
  }

  @override
  Future<void> softDeleteCompetency(String competencyId) async {
    final db = await localDatabase.database;
    final now = DateTime.now().toIso8601String();
    await db.update(
      DbTables.tosCompetencies,
      {
        CommonCols.deletedAt: now,
        CommonCols.updatedAt: now,
        CommonCols.needsSync: 1,
      },
      where: '${CommonCols.id} = ?',
      whereArgs: [competencyId],
    );
  }

  @override
  Future<void> bulkSaveCompetencies(List<CompetencyModel> competencies) async {
    final db = await localDatabase.database;
    final batch = db.batch();
    for (final comp in competencies) {
      batch.insert(
        DbTables.tosCompetencies,
        {
          ...comp.toMap(),
          CommonCols.needsSync: 1,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }
}
