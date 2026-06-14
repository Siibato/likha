import 'package:sqflite_sqlcipher/sqflite.dart';

import 'package:likha/core/database/db_schema.dart';
import 'package:likha/core/database/local_database.dart';
import 'package:likha/data/models/tos/tos_model.dart';

Future<void> cacheTosList(
  LocalDatabase localDatabase,
  List<TosModel> tosList,
) async {
  final db = await localDatabase.database;
  final batch = db.batch();
  for (final tos in tosList) {
    batch.insert(
      DbTables.tableOfSpecifications,
      {
        ...tos.toMap(),
        CommonCols.syncStatus: 'synced',
        CommonCols.cachedAt: DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
  await batch.commit(noResult: true);
}
