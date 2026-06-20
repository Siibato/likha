import 'package:likha/core/database/db_schema.dart';
import 'package:likha/core/database/local_database.dart';
import 'package:likha/data/models/grading/term_grade_model.dart';

Future<List<TermGradeModel>> getTermGradesByClass(
  LocalDatabase localDatabase,
  String classId,
  int termNumber,
) async {
  final db = await localDatabase.database;
  final results = await db.query(
    DbTables.termGrades,
    where:
        '${TermGradesCols.classId} = ? AND ${TermGradesCols.termNumber} = ?',
    whereArgs: [classId, termNumber],
  );
  return results.map((row) => TermGradeModel.fromMap(row)).toList();
}
