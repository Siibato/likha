import 'package:sqflite/sqflite.dart';

import 'package:likha/core/database/db_schema.dart';
import 'package:likha/data/models/grading/grade_config_model.dart';
import '../grading_local_datasource_base.dart';

mixin GradingConfigMixin on GradingLocalDataSourceBase {
  @override
  Future<List<GradeConfigModel>> getConfigByClass(String classId) async {
    final db = await localDatabase.database;
    final results = await db.query(
      DbTables.gradeRecord,
      where: '${GradeRecordCols.classId} = ?',
      whereArgs: [classId],
      orderBy: '${GradeRecordCols.gradingPeriodNumber} ASC',
    );
    return results.map((row) => GradeConfigModel.fromMap(row)).toList();
  }

  @override
  Future<void> saveConfigs(List<GradeConfigModel> configs) async {
    final db = await localDatabase.database;
    final batch = db.batch();
    for (final config in configs) {
      batch.insert(
        DbTables.gradeRecord,
        config.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }
}
