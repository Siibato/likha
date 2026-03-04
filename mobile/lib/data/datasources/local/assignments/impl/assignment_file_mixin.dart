import 'dart:io';
import 'package:likha/core/errors/exceptions.dart';
import 'package:likha/core/sync/sync_queue.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import '../assignment_local_datasource_base.dart';

mixin AssignmentFileMixin on AssignmentLocalDataSourceBase {
  @override
  Future<void> stageFileForUpload({
    required String submissionId,
    required String fileName,
    required String fileType,
    required int fileSize,
    required String localPath,
  }) async {
    try {
      final db = await localDatabase.database;
      final now = DateTime.now();
      final fileId = const Uuid().v4();

      final appDir = await getApplicationDocumentsDirectory();
      final uploadDir = Directory('${appDir.path}/offline_uploads');
      if (!await uploadDir.exists()) await uploadDir.create(recursive: true);

      final sourceFile = File(localPath);
      if (!await sourceFile.exists()) throw CacheException('Source file does not exist: $localPath');

      final stagedPath = '${uploadDir.path}/${fileId}_$fileName';
      await sourceFile.copy(stagedPath);

      await db.transaction((txn) async {
        await txn.insert(
          'submission_files',
          {
            'id': fileId,
            'submission_id': submissionId,
            'file_name': fileName,
            'file_type': fileType,
            'file_size': fileSize,
            'uploaded_at': now.toIso8601String(),
            'local_path': stagedPath,
            'is_local_only': 1,
            'cached_at': now.toIso8601String(),
          },
        );
        await syncQueue.enqueue(SyncQueueEntry(
          id: const Uuid().v4(),
          entityType: SyncEntityType.submissionFile,
          operation: SyncOperation.upload,
          payload: {
            'file_id': fileId,
            'submission_id': submissionId,
            'local_path': stagedPath,
            'file_name': fileName,
            'file_type': fileType,
            'file_size': fileSize,
          },
          status: SyncStatus.pending,
          retryCount: 0,
          maxRetries: 5,
          createdAt: now,
        ), txn: txn);
      });
    } catch (e) {
      throw CacheException('Failed to stage file for upload: $e');
    }
  }

  @override
  Future<bool> isFileCached(String fileId) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      return await File('${dir.path}/submission_file_cache/$fileId').exists();
    } catch (e) {
      return false;
    }
  }

  @override
  Future<List<int>> getCachedFileBytes(String fileId) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/submission_file_cache/$fileId');
      if (!await file.exists()) throw CacheException('File $fileId not cached');
      return await file.readAsBytes();
    } catch (e) {
      if (e is CacheException) rethrow;
      throw CacheException('Failed to read cached file: $e');
    }
  }

  @override
  Future<void> cacheFileBytes(String fileId, String fileName, List<int> bytes) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final cacheDir = Directory('${dir.path}/submission_file_cache');
      if (!await cacheDir.exists()) await cacheDir.create(recursive: true);

      final filePath = '${cacheDir.path}/$fileId';
      await File(filePath).writeAsBytes(bytes);

      final db = await localDatabase.database;
      await db.update(
        'submission_files',
        {'local_path': filePath},
        where: 'id = ?',
        whereArgs: [fileId],
      );
    } catch (e) {
      throw CacheException('Failed to cache file: $e');
    }
  }
}