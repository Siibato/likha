import 'package:likha/core/database/db_schema.dart';
import 'package:likha/core/database/local_database.dart';
import 'package:likha/data/models/grading/grade_score_model.dart';

Future<List<GradeScoreModel>> getScoresByItem(
  LocalDatabase localDatabase,
  String gradeItemId,
) async {
  final db = await localDatabase.database;
  final results = await db.query(
    DbTables.gradeScores,
    where: '${GradeScoresCols.gradeItemId} = ?',
    whereArgs: [gradeItemId],
  );
  return results.map((row) => GradeScoreModel.fromMap(row)).toList();
}
