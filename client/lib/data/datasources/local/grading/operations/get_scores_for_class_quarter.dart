import 'package:likha/core/database/db_schema.dart';
import 'package:likha/core/database/local_database.dart';
import 'package:likha/data/models/grading/grade_score_model.dart';

Future<List<GradeScoreModel>> getScoresForClassQuarter(
  LocalDatabase localDatabase,
  String classId,
  int quarter,
) async {
  final db = await localDatabase.database;
  final results = await db.rawQuery(
    '''
    SELECT gs.*
    FROM ${DbTables.gradeScores} gs
    INNER JOIN ${DbTables.gradeItems} gi
      ON gs.${GradeScoresCols.gradeItemId} = gi.${CommonCols.id}
    WHERE gi.${GradeItemsCols.classId} = ?
      AND gi.${GradeItemsCols.termNumber} = ?
    ''',
    [classId, quarter],
  );
  return results.map((row) => GradeScoreModel.fromMap(row)).toList();
}
