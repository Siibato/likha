import 'package:likha/core/database/db_schema.dart';
import 'package:likha/core/database/local_database.dart';
import 'package:likha/data/models/grading/period_grade_model.dart';

Future<List<PeriodGradeModel>> getPeriodGradesByClassOp(
  LocalDatabase localDatabase,
  String classId,
  int gradingPeriodNumber,
) async {
  final db = await localDatabase.database;
  final results = await db.query(
    DbTables.periodGrades,
    where:
        '${PeriodGradesCols.classId} = ? AND ${PeriodGradesCols.gradingPeriodNumber} = ?',
    whereArgs: [classId, gradingPeriodNumber],
  );
  return results.map((row) => PeriodGradeModel.fromMap(row)).toList();
}
