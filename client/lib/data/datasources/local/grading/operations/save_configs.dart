import 'package:sqflite_sqlcipher/sqflite.dart';

import 'package:likha/core/database/db_schema.dart';
import 'package:likha/core/database/local_database.dart';
import 'package:likha/data/models/grading/grade_config_model.dart';

Future<void> saveConfigs(
  LocalDatabase localDatabase,
  List<GradeConfigModel> configs,
) async {
  final db = await localDatabase.database;
  final batch = db.batch();
  for (final config in configs) {
    batch.insert(
      DbTables.gradeRecord,
      config.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
  await batch.commit(noResult: true);
}
