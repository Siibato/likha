import 'package:likha/core/database/db_schema.dart';
import 'package:likha/core/database/local_database.dart';
import 'package:likha/core/errors/exceptions.dart';

Future<void> markAssessmentPublishedLocallyOp(
  LocalDatabase localDatabase,
  String assessmentId,
) async {
  try {
    final db = await localDatabase.database;
    await db.update(
      'assessments',
      {
        AssessmentsCols.isPublished: 1,
        CommonCols.updatedAt: DateTime.now().toIso8601String(),
        CommonCols.cachedAt: DateTime.now().toIso8601String(),
        CommonCols.needsSync: 1,
      },
      where: '${CommonCols.id} = ?',
      whereArgs: [assessmentId],
    );
  } catch (e) {
    throw CacheException('Failed to mark assessment as published locally: $e');
  }
}
