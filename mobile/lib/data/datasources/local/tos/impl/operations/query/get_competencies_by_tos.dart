import 'package:likha/core/database/db_schema.dart';
import 'package:likha/core/database/local_database.dart';
import 'package:likha/data/models/tos/tos_model.dart';

Future<List<CompetencyModel>> getCompetenciesByTosOp(
  LocalDatabase localDatabase,
  String tosId,
) async {
  final db = await localDatabase.database;
  final results = await db.query(
    DbTables.tosCompetencies,
    where:
        '${TosCompetenciesCols.tosId} = ? AND ${CommonCols.deletedAt} IS NULL',
    whereArgs: [tosId],
    orderBy: '${TosCompetenciesCols.orderIndex} ASC',
  );
  return results.map((row) => CompetencyModel.fromMap(row)).toList();
}
