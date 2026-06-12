import 'package:likha/core/database/db_schema.dart';
import 'package:likha/core/errors/exceptions.dart';
import 'package:likha/core/database/local_database.dart';

Future<void> updateAssignmentOrderLocallyOp(
  LocalDatabase localDatabase,
  String assignmentId,
  int orderIndex,
) async {
  try {
    final db = await localDatabase.database;
    final now = DateTime.now();
    await db.update(
      DbTables.assignments,
      {
        AssignmentsCols.orderIndex: orderIndex,
        CommonCols.updatedAt: now.toIso8601String(),
        CommonCols.cachedAt: now.toIso8601String(),
        CommonCols.needsSync: 1,
      },
      where: '${CommonCols.id} = ?',
      whereArgs: [assignmentId],
    );
  } catch (e) {
    throw CacheException('Failed to update assignment order locally: $e');
  }
}
