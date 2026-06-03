import 'package:sqflite/sqflite.dart';

import 'package:likha/core/database/db_schema.dart';
import 'package:likha/core/database/local_database.dart';
import 'package:likha/data/models/grading/grade_item_model.dart';

Future<List<GradeItemModel>> getItemsByClassQuarterOp(
  LocalDatabase localDatabase,
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
