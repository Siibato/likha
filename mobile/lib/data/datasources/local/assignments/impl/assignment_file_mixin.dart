import '../assignment_local_datasource_base.dart';
import 'operations/file/stage_file_for_upload.dart';
import 'operations/file/is_file_cached.dart';
import 'operations/file/get_cached_file_bytes.dart';
import 'operations/file/cache_file_bytes.dart';

mixin AssignmentFileMixin on AssignmentLocalDataSourceBase {
  @override
  Future<void> stageFileForUpload({
    required String submissionId,
    required String fileName,
    required String fileType,
    required int fileSize,
    required String localPath,
  }) async {
    return stageFileForUploadOp(localDatabase, syncQueue, submissionId, fileName, fileType, fileSize, localPath);
  }

  @override
  Future<bool> isFileCached(String fileId) async {
    return isFileCachedOp(localDatabase, fileId);
  }

  @override
  Future<List<int>> getCachedFileBytes(String fileId) async {
    return getCachedFileBytesOp(localDatabase, fileId);
  }

  @override
  Future<void> cacheFileBytes(String fileId, String fileName, List<int> bytes) async {
    return cacheFileBytesOp(localDatabase, fileId, fileName, bytes);
  }
}