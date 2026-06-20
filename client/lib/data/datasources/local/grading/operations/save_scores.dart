import 'package:sqflite_sqlcipher/sqflite.dart';

import 'package:likha/core/database/db_schema.dart';
import 'package:likha/core/database/local_database.dart';
import 'package:likha/data/models/grading/grade_score_model.dart';

Future<void> saveScores(
  LocalDatabase localDatabase,
  List<GradeScoreModel> scores, {
  Transaction? txn,
}) async {
  final db = txn ?? await localDatabase.database;
  final batch = db.batch();
  for (final score in scores) {
    final map = score.toMap();
    if (score.syncStatus != null) {
      map[CommonCols.syncStatus] = score.syncStatus;
    }
    batch.insert(
      DbTables.gradeScores,
      map,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
  await batch.commit(noResult: true);
}
