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

        await localDataSource.stageMaterialFileForUpload(
          materialId: materialId,
          fileName: fileName,
          fileType: mime,
          fileSize: size,
          localPath: filePath,
        );

        return Right(MaterialFile(
          id: '',
          fileName: fileName,
          fileType: mime,
          fileSize: size,
          uploadedAt: DateTime.now(),
        ));
      }

      final result = await remoteDataSource.uploadFile(
        materialId: materialId,
        filePath: filePath,
        fileName: fileName,
      );
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
        await localDataSource.cacheFile(fileId, fileId, result);
      } catch (_) {
        // Ignore caching errors — still return the file
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