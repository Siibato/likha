import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:likha/core/database/local_database.dart';
import 'package:likha/core/errors/exceptions.dart';
import 'package:likha/core/sync/sync_queue.dart';
import 'package:likha/core/database/db_schema.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

Future<void> stageMaterialFileForUploadOp(
  LocalDatabase localDatabase,
  SyncQueue syncQueue,
  String materialId,
  String fileName,
  String fileType,
  int fileSize,
  String localPath,
) async {
  if (kIsWeb) throw CacheException('File staging not supported on web');
  try {
    final db = await localDatabase.database;
    final now = DateTime.now();
    final fileId = const Uuid().v4();

    final appDir = await getApplicationDocumentsDirectory();
    final uploadDir = Directory('${appDir.path}/offline_uploads');
    if (!await uploadDir.exists()) await uploadDir.create(recursive: true);

    final sourceFile = File(localPath);
    if (!await sourceFile.exists()) {
      throw CacheException('Source file does not exist: $localPath');
    }

    final stagedPath = '${uploadDir.path}/${fileId}_$fileName';
    await sourceFile.copy(stagedPath);

    await db.transaction((txn) async {
      await txn.insert(
        DbTables.materialFiles,
        {
          CommonCols.id: fileId,
          MaterialFilesCols.materialId: materialId,
          MaterialFilesCols.fileName: fileName,
          MaterialFilesCols.fileType: fileType,
          MaterialFilesCols.fileSize: fileSize,
          MaterialFilesCols.localPath: stagedPath,
          MaterialFilesCols.uploadedAt: now.toIso8601String(),
          CommonCols.cachedAt: now.toIso8601String(),
          CommonCols.needsSync: 1,
        },
      );
      await syncQueue.enqueue(SyncQueueEntry(
        id: const Uuid().v4(),
        entityType: SyncEntityType.materialFile,
        operation: SyncOperation.upload,
        payload: {
          'file_id': fileId,
          'material_id': materialId,
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
    throw CacheException('Failed to stage material file for upload: $e');
  }
}
