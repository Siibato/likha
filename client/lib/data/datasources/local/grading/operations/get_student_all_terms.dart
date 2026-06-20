import 'package:likha/core/database/db_schema.dart';
import 'package:likha/core/database/local_database.dart';
import 'package:likha/data/models/grading/term_grade_model.dart';

Future<List<TermGradeModel>> getStudentAllTerms(
  LocalDatabase localDatabase,
  String classId,
  String studentId,
) async {
  final db = await localDatabase.database;
  final results = await db.query(
    DbTables.termGrades,
    where:
        '${TermGradesCols.classId} = ? AND ${TermGradesCols.studentId} = ?',
    whereArgs: [classId, studentId],
    orderBy: '${TermGradesCols.termNumber} ASC',
  );
  return results.map((row) => TermGradeModel.fromMap(row)).toList();
}
