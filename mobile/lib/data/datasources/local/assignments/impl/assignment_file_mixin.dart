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
            'cached_at': now.toIso8601String(),
            'needs_sync': 1,
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
          maxRetries: 3,
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
      final db = await localDatabase.database;

      // Get file metadata from DB to find the expected filename
      final results = await db.query(
        'submission_files',
        where: 'id = ?',
        whereArgs: [fileId],
      );

      if (results.isEmpty) {
        return false;
      }

      final fileName = results.first['file_name'] as String?;
      if (fileName == null || fileName.isEmpty) {
        return false;
      }

      // Construct expected path using naming convention: {nameWithoutExt}-{shortId}.{ext}
      final expectedPath = await getExpectedFilePath(fileId, fileName);
      if (expectedPath == null) {
        return false;
      }

      // Check if file actually exists at expected location
      final file = File(expectedPath);
      final exists = await file.exists();

      // If exists but DB path is empty/stale, update it for next time
      final storedPath = results.first['local_path'] as String?;
      if (exists && (storedPath == null || storedPath.isEmpty)) {
        await db.update(
          'submission_files',
          {'local_path': expectedPath},
          where: 'id = ?',
          whereArgs: [fileId],
        );
      }

      return exists;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<List<int>> getCachedFileBytes(String fileId) async {
    try {
      final db = await localDatabase.database;
      final results = await db.query(
        'submission_files',
        where: 'id = ?',
        whereArgs: [fileId],
      );

      if (results.isEmpty) {
        throw CacheException('File $fileId not found in database');
      }

      final fileName = results.first['file_name'] as String?;
      if (fileName == null || fileName.isEmpty) {
        throw CacheException('File $fileId has no fileName in database');
      }

      // Use expected path based on naming convention
      final expectedPath = await getExpectedFilePath(fileId, fileName);
      if (expectedPath == null) {
        throw CacheException('Could not construct expected path for file $fileId');
      }

      final file = File(expectedPath);

      if (!await file.exists()) {
        // Clean up DB entry
        await db.update(
          'submission_files',
          {'local_path': ''},
          where: 'id = ?',
          whereArgs: [fileId],
        );
        throw CacheException('File not found at: $expectedPath');
      }

      return await file.readAsBytes();
    } catch (e) {
      if (e is CacheException) rethrow;
      throw CacheException('Failed to get cached file: $e');
    }
  }

  @override
  Future<void> cacheFileBytes(String fileId, String fileName, List<int> bytes) async {
    try {
      final appDirDoc = await getApplicationDocumentsDirectory();
      final submissionFilesDir = Directory('${appDirDoc.path}/submission_files');
      if (!await submissionFilesDir.exists()) {
        await submissionFilesDir.create(recursive: true);
      }

      // Query submission_files for the canonical file_name to ensure correct extension
      final db = await localDatabase.database;
      final rows = await db.query(
        'submission_files',
        columns: ['file_name'],
        where: 'id = ?',
        whereArgs: [fileId],
      );
      final storedFileName = rows.isNotEmpty
          ? rows.first['file_name'] as String?
          : null;
      final finalFileName = storedFileName ?? fileName;

      // Apply naming convention: {nameWithoutExt}-{shortId}.{ext}
      final shortId = fileId.substring(0, 8);
      final dotIndex = finalFileName.lastIndexOf('.');
      final localFileName = dotIndex > 0
          ? '${finalFileName.substring(0, dotIndex)}-$shortId${finalFileName.substring(dotIndex)}'
          : '$finalFileName-$shortId';
      final filePath = '${submissionFilesDir.path}/$localFileName';

      await File(filePath).writeAsBytes(bytes);

      // Update DB with the cached file path
      await db.update(
        'submission_files',
        {
          'local_path': filePath,
          'cached_at': DateTime.now().toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [fileId],
      );
    } catch (e) {
      throw CacheException('Failed to cache file: $e');
    }
  }

  /// Get expected file path based on fileId and fileName
  /// Uses naming convention: {nameWithoutExt}-{shortId}.{ext}
  /// Example: report.pdf with fileId cfa3d566-... → report-cfa3d566.pdf
  Future<String?> getExpectedFilePath(String fileId, String fileName) async {
    try {
      final appDirDoc = await getApplicationDocumentsDirectory();
      final submissionFilesDir = Directory('${appDirDoc.path}/submission_files');

      final shortId = fileId.substring(0, 8);
      final dotIndex = fileName.lastIndexOf('.');
      final localFileName = dotIndex > 0
          ? '${fileName.substring(0, dotIndex)}-$shortId${fileName.substring(dotIndex)}'
          : '$fileName-$shortId';
      final expectedPath = '${submissionFilesDir.path}/$localFileName';
      return expectedPath;
    } catch (e) {
      return null;
    }
  }
}