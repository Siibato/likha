import 'package:sqflite_sqlcipher/sqflite.dart';

import 'package:likha/core/database/db_schema.dart';
import 'package:likha/core/database/local_database.dart';
import 'package:likha/data/models/grading/term_grade_model.dart';

Future<void> saveTermGrades(
  LocalDatabase localDatabase,
  List<TermGradeModel> grades,
) async {
  final db = await localDatabase.database;
  final batch = db.batch();
  for (final grade in grades) {
    batch.insert(
      DbTables.termGrades,
      grade.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
  await batch.commit(noResult: true);
}
