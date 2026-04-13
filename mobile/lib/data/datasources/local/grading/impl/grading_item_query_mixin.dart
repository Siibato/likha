import 'package:sqflite/sqflite.dart';

import 'package:likha/core/database/db_schema.dart';
import 'package:likha/data/models/grading/grade_item_model.dart';
import '../grading_local_datasource_base.dart';

mixin GradingItemQueryMixin on GradingLocalDataSourceBase {
  @override
  Future<List<GradeItemModel>> getItemsByClassQuarter(
    String classId,
    int quarter, {
    String? component,
  }) async {
    final db = await localDatabase.database;
    var where =
        '${GradeItemsCols.classId} = ? AND ${GradeItemsCols.gradingPeriodNumber} = ?';
    final whereArgs = <dynamic>[classId, quarter];

    if (component != null) {
      where += ' AND ${GradeItemsCols.component} = ?';
      whereArgs.add(component);
    }

    final results = await db.query(
      DbTables.gradeItems,
      where: where,
      whereArgs: whereArgs,
      orderBy: '${GradeItemsCols.orderIndex} ASC',
    );
    return results.map((row) => GradeItemModel.fromMap(row)).toList();
  }

  @override
  Future<void> saveItems(List<GradeItemModel> items) async {
    final db = await localDatabase.database;
    final batch = db.batch();
    for (final item in items) {
      batch.insert(
        DbTables.gradeItems,
        item.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  @override
  Future<void> saveItem(GradeItemModel item) async {
    final db = await localDatabase.database;
    await db.insert(
      DbTables.gradeItems,
      item.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<void> deleteItem(String id) async {
    final db = await localDatabase.database;
    await db.delete(
      DbTables.gradeItems,
      where: '${CommonCols.id} = ?',
      whereArgs: [id],
    );
  }

  @override
  Future<GradeItemModel?> getItemBySourceId(String sourceId) async {
    final db = await localDatabase.database;
    final results = await db.query(
      DbTables.gradeItems,
      where: '${GradeItemsCols.sourceId} = ? AND ${CommonCols.deletedAt} IS NULL',
      whereArgs: [sourceId],
      limit: 1,
    );
    if (results.isEmpty) return null;
    return GradeItemModel.fromMap(results.first);
  }
}
