import 'package:likha/core/database/db_schema.dart';
import 'package:likha/core/errors/exceptions.dart';
import '../grading_local_datasource_base.dart';

mixin GradingClearMixin on GradingLocalDataSourceBase {
  @override
  Future<void> clearAllCache() async {
    try {
      final db = await localDatabase.database;
      await db.delete(DbTables.gradeScores);
      await db.delete(DbTables.gradeItems);
      await db.delete(DbTables.gradeRecord);
      await db.delete(DbTables.periodGrades);
      await db.delete(DbTables.studentResultsCache);
    } catch (e) {
      throw CacheException('Failed to clear grading cache: $e');
    }
  }
}
