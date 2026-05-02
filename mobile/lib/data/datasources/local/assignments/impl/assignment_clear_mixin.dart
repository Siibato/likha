import 'dart:io';
import 'package:likha/core/database/db_schema.dart';
import 'package:likha/core/errors/exceptions.dart';
import 'package:likha/core/logging/cache_logger.dart';
import 'package:path_provider/path_provider.dart';
import '../assignment_local_datasource_base.dart';

mixin AssignmentClearMixin on AssignmentLocalDataSourceBase {
  @override
  Future<void> clearAllCache() async {
    try {
      final db = await localDatabase.database;
      await db.delete(DbTables.assignments);
      await db.delete(DbTables.assignmentSubmissions);
      await db.delete(DbTables.submissionFiles);

      try {
        final dir = await getApplicationDocumentsDirectory();
        final cacheDir = Directory('${dir.path}/submission_file_cache');
        if (await cacheDir.exists()) await cacheDir.delete(recursive: true);
      } catch (e) {
        CacheLogger.instance.error('Failed to delete submission_file_cache directory during logout', e);
      }
    } catch (e) {
      throw CacheException('Failed to clear assignment cache: $e');
    }
  }
}