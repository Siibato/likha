import 'package:likha/core/database/db_schema.dart';
import 'package:likha/core/database/local_database.dart';
import 'package:likha/data/models/grading/grade_config_model.dart';

Future<List<GradeConfigModel>> getConfigByClassOp(
  LocalDatabase localDatabase,
  String classId,
) async {
  final db = await localDatabase.database;
  final results = await db.query(
    DbTables.gradeRecord,
    where: '${GradeRecordCols.classId} = ?',
    whereArgs: [classId],
    orderBy: '${GradeRecordCols.gradingPeriodNumber} ASC',
  );
  return results.map((row) => GradeConfigModel.fromMap(row)).toList();
}
