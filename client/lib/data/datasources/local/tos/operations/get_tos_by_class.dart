import 'package:likha/core/database/db_schema.dart';
import 'package:likha/core/database/local_database.dart';
import 'package:likha/data/models/tos/tos_model.dart';

Future<List<TosModel>> getTosByClass(
  LocalDatabase localDatabase,
  String classId,
) async {
  final db = await localDatabase.database;
  final results = await db.query(
    DbTables.tableOfSpecifications,
    where: '${TosCols.classId} = ? AND ${CommonCols.deletedAt} IS NULL',
    whereArgs: [classId],
    orderBy: '${TosCols.gradingPeriodNumber} ASC',
  );
  return results.map((row) => TosModel.fromMap(row)).toList();
}
