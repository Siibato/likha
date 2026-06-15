import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:likha/core/database/local_database.dart';
import 'package:likha/core/errors/exceptions.dart';
import 'package:likha/core/sync/sync_queue.dart';
import 'package:likha/core/database/db_schema.dart';
import 'package:path_provider/path_provider.dart';

Future<String> stageMaterialFileForUpload(
  LocalDatabase localDatabase,
  SyncQueue syncQueue,
  String materialId,
  String fileName,
  String fileType,
  int fileSize,
  String localPath,
  String fileId, {
  Transaction? txn,
}) async {
  if (kIsWeb) throw CacheException('File staging not supported on web');
  try {
    final now = DateTime.now();

    final appDir = await getApplicationDocumentsDirectory();
    final uploadDir = Directory('${appDir.path}/offline_uploads');
    if (!await uploadDir.exists()) await uploadDir.create(recursive: true);

    final sourceFile = File(localPath);
    if (!await sourceFile.exists()) {
      throw CacheException('Source file does not exist: $localPath');
    }

    final stagedPath = '${uploadDir.path}/${fileId}_$fileName';
    await sourceFile.copy(stagedPath);

    final executor = txn ?? await localDatabase.database;
    await executor.insert(
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
        CommonCols.syncStatus: 'pending',
      },
    );

    return stagedPath;
  } catch (e) {
    throw CacheException('Failed to stage material file for upload: $e');
  }
}
