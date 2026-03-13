import 'package:dartz/dartz.dart';
import 'package:likha/core/errors/exceptions.dart';
import 'package:likha/core/errors/failures.dart';
import 'package:likha/core/sync/sync_queue.dart';
import 'package:likha/core/utils/typedef.dart';
import 'package:likha/data/repositories/learning_materials/learning_material_repository_base.dart';
import 'package:likha/domain/learning_materials/entities/material_file.dart';
import 'package:uuid/uuid.dart';

mixin LearningMaterialFileMixin on LearningMaterialRepositoryBase {
  @override
  ResultFuture<MaterialFile> uploadFile({
    required String materialId,
    required String filePath,
    required String fileName,
  }) async {
    try {
      if (!serverReachabilityService.isServerReachable) {
        final mime = mimeType(filePath);
        final size = await fileSize(filePath);

        final localFileId = const Uuid().v4();
        await localDataSource.stageMaterialFileForUpload(
          materialId: materialId,
          fileName: fileName,
          fileType: mime,
          fileSize: size,
          localPath: filePath,
        );

        return Right(MaterialFile(
          id: localFileId,
          fileName: fileName,
          fileType: mime,
          fileSize: size,
          uploadedAt: DateTime.now(),
          localPath: filePath,
          needsSync: true,
          cachedAt: DateTime.now(),
        ));
      }

      final result = await remoteDataSource.uploadFile(
        materialId: materialId,
        filePath: filePath,
        fileName: fileName,
      );

      try {
        print('[UPLOAD_POST] ✅ File uploaded successfully, fetching material detail...');
        final materialDetail = await remoteDataSource.getMaterialDetail(materialId: materialId);
        print('[UPLOAD_POST] 📄 Got material detail: ${materialDetail.files.length} files');

        if (materialDetail.files.isNotEmpty) {
          print('[UPLOAD_POST] 💾 Caching ${materialDetail.files.length} files to local DB...');
          await localDataSource.cacheMaterialFiles(materialId, materialDetail.files);
          print('[UPLOAD_POST] ✅ Cache complete, notifying event bus...');
        } else {
          print('[UPLOAD_POST] ⚠️  No files in response, skipping cache');
        }

        dataEventBus.notifyMaterialsChanged(materialDetail.classId);
      } catch (e) {
        print('[UPLOAD_POST] ❌ Error during post-upload caching: $e');
      }

      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  ResultVoid deleteFile({required String fileId}) async {
    try {
      if (!serverReachabilityService.isServerReachable) {
        try {
          await localDataSource.deleteMaterialFileLocally(fileId);
        } catch (_) {}

        await syncQueue.enqueue(SyncQueueEntry(
          id: const Uuid().v4(),
          entityType: SyncEntityType.materialFile,
          operation: SyncOperation.delete,
          payload: {'file_id': fileId},
          status: SyncStatus.pending,
          retryCount: 0,
          maxRetries: 5,
          createdAt: DateTime.now(),
        ));
        return const Right(null);
      }

      await remoteDataSource.deleteFile(fileId: fileId);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  ResultFuture<List<int>> downloadFile({required String fileId}) async {
    try {
      if (await localDataSource.isFileCached(fileId)) {
        final cachedFile = await localDataSource.getCachedFile(fileId);
        return Right(cachedFile);
      }

      final result = await remoteDataSource.downloadFile(fileId: fileId);

      try {
        print('[DL_FILE] ✅ Downloaded ${result.length} bytes, caching...');
        // Pass empty fileName to let datasource look it up from material_files table
        await localDataSource.cacheFile(fileId, '', result);
        print('[DL_FILE] ✅ File cached successfully');
      } catch (e) {
        // Log the error but still return file — user can open it from memory
        // Next app start: file won't be cached, will need re-download
        print('[DL_FILE] ⚠️  Cache write failed: $e (file still available in memory)');
      }

      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

}