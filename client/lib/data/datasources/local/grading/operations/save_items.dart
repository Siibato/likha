import 'package:sqflite_sqlcipher/sqflite.dart';

import 'package:likha/core/database/db_schema.dart';
import 'package:likha/core/database/local_database.dart';
import 'package:likha/data/models/grading/grade_item_model.dart';

Future<void> saveItems(
  LocalDatabase localDatabase,
  List<GradeItemModel> items,
) async {
  final db = await localDatabase.database;
  final batch = db.batch();
  for (final item in items) {
    batch.insert(
      DbTables.gradeItems,
      item.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
  await batch.commit(noResult: true);
}
