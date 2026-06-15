import 'package:likha/core/database/db_schema.dart';
import 'package:likha/core/database/local_database.dart';
import 'package:likha/data/models/grading/grade_item_model.dart';

Future<GradeItemModel?> getItemBySourceIdOp(
  LocalDatabase localDatabase,
  String sourceId,
) async {
  final db = await localDatabase.database;
  final results = await db.query(
    DbTables.gradeItems,
    where: '${GradeItemsCols.sourceId} = ? AND ${CommonCols.deletedAt} IS NULL',
    whereArgs: [sourceId],
    limit: 1,
  );
  if (results.isEmpty) return null;
  return GradeItemModel.fromMap(results.first);
}
