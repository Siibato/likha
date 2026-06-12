import 'package:likha/core/database/db_schema.dart';
import 'package:likha/core/database/local_database.dart';
import 'package:likha/data/models/tos/tos_model.dart';

Future<TosModel?> getTosById(
  LocalDatabase localDatabase,
  String tosId,
) async {
  final db = await localDatabase.database;
  final results = await db.query(
    DbTables.tableOfSpecifications,
    where: '${CommonCols.id} = ? AND ${CommonCols.deletedAt} IS NULL',
    whereArgs: [tosId],
    limit: 1,
  );
  if (results.isEmpty) return null;
  return TosModel.fromMap(results.first);
}
