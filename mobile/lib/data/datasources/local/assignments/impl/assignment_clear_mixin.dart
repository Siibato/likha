import 'dart:io';
import 'package:likha/core/errors/exceptions.dart';
import 'package:path_provider/path_provider.dart';
import '../assignment_local_datasource_base.dart';

mixin AssignmentClearMixin on AssignmentLocalDataSourceBase {
  @override
  Future<void> clearAllCache() async {
    try {
      final db = await localDatabase.database;
      await db.delete('assignments');
      await db.delete('assignment_submissions');
      await db.delete('submission_files');

      try {
        final dir = await getApplicationDocumentsDirectory();
        final cacheDir = Directory('${dir.path}/submission_file_cache');
        if (await cacheDir.exists()) await cacheDir.delete(recursive: true);
      } catch (_) {
        // Ignore file system errors
      }
    } catch (e) {
      throw CacheException('Failed to clear assignment cache: $e');
    }
  }
}