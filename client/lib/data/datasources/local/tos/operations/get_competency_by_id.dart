import 'package:sqflite_sqlcipher/sqflite.dart';

import 'package:likha/core/database/db_schema.dart';
import 'package:likha/core/database/local_database.dart';
import 'package:likha/data/models/tos/tos_model.dart';

Future<CompetencyModel?> getCompetencyById(
  LocalDatabase localDatabase,
  String competencyId, {
  Transaction? txn,
}) async {
  final db = txn ?? await localDatabase.database;
  final results = await db.query(
    DbTables.tosCompetencies,
    where: '${CommonCols.id} = ? AND ${CommonCols.deletedAt} IS NULL',
    whereArgs: [competencyId],
    limit: 1,
  );
  if (results.isEmpty) return null;
  return CompetencyModel.fromMap(results.first);
}
