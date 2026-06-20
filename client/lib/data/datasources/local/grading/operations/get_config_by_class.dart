import 'package:likha/core/database/db_schema.dart';
import 'package:likha/core/database/local_database.dart';
import 'package:likha/data/models/grading/grade_config_model.dart';

Future<List<GradeConfigModel>> getConfigByClass(
  LocalDatabase localDatabase,
  String classId,
) async {
  final db = await localDatabase.database;
  final results = await db.query(
    DbTables.gradeRecord,
    where: '${GradeRecordCols.classId} = ?',
    whereArgs: [classId],
    orderBy: '${GradeRecordCols.termNumber} ASC',
  );
  return results.map((row) => GradeConfigModel.fromMap(row)).toList();
}
