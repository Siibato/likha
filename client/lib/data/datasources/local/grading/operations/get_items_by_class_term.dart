import 'package:likha/core/database/db_schema.dart';
import 'package:likha/core/database/local_database.dart';
import 'package:likha/data/models/grading/grade_item_model.dart';

Future<List<GradeItemModel>> getItemsByClassTerm(
  LocalDatabase localDatabase,
  String classId,
  int term, {
  String? component,
}) async {
  final db = await localDatabase.database;
  var where =
      '${GradeItemsCols.classId} = ? AND ${GradeItemsCols.termNumber} = ?';
  final whereArgs = <dynamic>[classId, term];

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
