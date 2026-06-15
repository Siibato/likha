import 'package:sqflite_sqlcipher/sqflite.dart';

import 'package:likha/core/database/db_schema.dart';
import 'package:likha/core/database/local_database.dart';
import 'package:likha/data/models/grading/grade_score_model.dart';

Future<void> saveScoresOp(
  LocalDatabase localDatabase,
  List<GradeScoreModel> scores,
) async {
  final db = await localDatabase.database;
  final batch = db.batch();
  for (final score in scores) {
    batch.insert(
      DbTables.gradeScores,
      score.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
  await batch.commit(noResult: true);
}
