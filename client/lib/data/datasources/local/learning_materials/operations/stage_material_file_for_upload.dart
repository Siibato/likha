import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:likha/core/database/local_database.dart';
import 'package:likha/core/errors/exceptions.dart';
import 'package:likha/core/logging/repo_logger.dart';
import 'package:likha/core/sync/sync_queue.dart';
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
    RepoLogger.instance.log('stageMaterialFileForUpload: material_id=${materialId.substring(0, 8)} file_id=${fileId.substring(0, 8)} file=$fileName');

    final appDir = await getApplicationDocumentsDirectory();
    final uploadDir = Directory('${appDir.path}/offline_uploads');
    if (!await uploadDir.exists()) await uploadDir.create(recursive: true);

    RepoLogger.instance.log('stageMaterialFileForUpload: upload_dir=$uploadDir');

    final sourceFile = File(localPath);
    if (!await sourceFile.exists()) {
      RepoLogger.instance.error('stageMaterialFileForUpload: source file not found at $localPath');
      throw CacheException('Source file does not exist: $localPath');
    }

    final stagedPath = '${uploadDir.path}/${fileId}_$fileName';
    RepoLogger.instance.log('stageMaterialFileForUpload: copying $localPath to $stagedPath');
    await sourceFile.copy(stagedPath);

    RepoLogger.instance.log('stageMaterialFileForUpload: file staged successfully');
    return stagedPath;
  } catch (e) {
    RepoLogger.instance.error('stageMaterialFileForUpload: failed - $e');
    throw CacheException('Failed to stage material file for upload: $e');
  }
}
