import 'package:sqflite/sqflite.dart';

import 'package:likha/core/database/db_schema.dart';
import 'package:likha/data/models/tos/tos_model.dart';
import '../tos_local_datasource_base.dart';

mixin TosCacheMixin on TosLocalDataSourceBase {
  @override
  Future<void> cacheTosList(List<TosModel> tosList) async {
    final db = await localDatabase.database;
    final batch = db.batch();
    for (final tos in tosList) {
      batch.insert(
        DbTables.tableOfSpecifications,
        {
          ...tos.toMap(),
          CommonCols.needsSync: 0,
          CommonCols.cachedAt: DateTime.now().toIso8601String(),
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  @override
  Future<void> cacheCompetencies(
    String tosId,
    List<CompetencyModel> competencies,
  ) async {
    final db = await localDatabase.database;
    final batch = db.batch();
    for (final comp in competencies) {
      batch.insert(
        DbTables.tosCompetencies,
        {
          ...comp.toMap(),
          CommonCols.needsSync: 0,
          CommonCols.cachedAt: DateTime.now().toIso8601String(),
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }
}
