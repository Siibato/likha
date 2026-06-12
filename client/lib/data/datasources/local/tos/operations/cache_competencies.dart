import 'package:sqflite_sqlcipher/sqflite.dart';

import 'package:likha/core/database/db_schema.dart';
import 'package:likha/core/database/local_database.dart';
import 'package:likha/data/models/tos/tos_model.dart';

Future<void> cacheCompetencies(
  LocalDatabase localDatabase,
  String tosId,
  List<CompetencyModel> competencies,
) async {
  if (competencies.isEmpty) return;
  final db = await localDatabase.database;
  final now = DateTime.now().toIso8601String();
  for (final comp in competencies) {
    final row = {
      ...comp.toMap(),
      CommonCols.needsSync: 0,
      CommonCols.cachedAt: now,
    };
    // Insert new rows that don't exist locally yet.
    await db.insert(
      DbTables.tosCompetencies,
      row,
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
    // Update existing rows ONLY if they have no pending local edits.
    // Rows with needs_sync = 1 have unsent changes — don't overwrite them
    // with potentially stale server data.
    await db.update(
      DbTables.tosCompetencies,
      row,
      where: '${CommonCols.id} = ? AND ${CommonCols.needsSync} = 0',
      whereArgs: [comp.id],
    );
  }
}
