import 'package:likha/core/errors/exceptions.dart';
import 'package:likha/core/database/db_schema.dart';
import 'package:likha/core/database/local_database.dart';

Future<void> deleteAssessmentLocallyOp(
  LocalDatabase localDatabase,
  String assessmentId,
) async {
  try {
    final db = await localDatabase.database;
    await db.update(
      DbTables.assessments,
      {
        CommonCols.deletedAt: DateTime.now().toIso8601String(),
        CommonCols.needsSync: 1,
        CommonCols.updatedAt: DateTime.now().toIso8601String(),
      },
      where: '${CommonCols.id} = ?',
      whereArgs: [assessmentId],
    );
  } catch (e) {
    throw CacheException('Failed to delete assessment locally: $e');
  }
}
