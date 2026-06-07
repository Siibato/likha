import 'package:likha/core/database/db_schema.dart';
import 'package:likha/core/database/local_database.dart';
import 'package:likha/data/models/grading/period_grade_model.dart';

Future<List<PeriodGradeModel>> getStudentAllPeriodsOp(
  LocalDatabase localDatabase,
  String classId,
  String studentId,
) async {
  final db = await localDatabase.database;
  final results = await db.query(
    DbTables.periodGrades,
    where:
        '${PeriodGradesCols.classId} = ? AND ${PeriodGradesCols.studentId} = ?',
    whereArgs: [classId, studentId],
    orderBy: '${PeriodGradesCols.gradingPeriodNumber} ASC',
  );
  return results.map((row) => PeriodGradeModel.fromMap(row)).toList();
}
