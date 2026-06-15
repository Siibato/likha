import 'package:sqflite_sqlcipher/sqflite.dart';

import 'package:likha/core/database/db_schema.dart';
import 'package:likha/core/database/local_database.dart';
import 'package:likha/data/models/grading/grade_item_model.dart';

Future<void> saveItem(
  LocalDatabase localDatabase,
  GradeItemModel item, {
  Transaction? txn,
}) async {
  final executor = txn ?? await localDatabase.database;
  await executor.insert(
    DbTables.gradeItems,
    {
      ...item.toMap(),
      CommonCols.syncStatus: 'pending',
    },
    conflictAlgorithm: ConflictAlgorithm.replace,
  );
}
