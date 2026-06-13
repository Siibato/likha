import 'package:dartz/dartz.dart';
import 'package:likha/core/errors/exceptions.dart';
import 'package:likha/core/errors/failures.dart';
import 'package:likha/core/logging/repo_logger.dart';
import 'package:likha/core/network/server_reachability_service.dart';
import 'package:likha/core/utils/typedef.dart';
import 'package:likha/data/datasources/local/learning_materials/learning_material_local_datasource.dart';
import 'package:likha/data/datasources/remote/learning_materials/learning_material_remote_datasource.dart';
import 'package:likha/domain/learning_materials/entities/material_file.dart';
import 'package:uuid/uuid.dart';
import '_helpers.dart' as helpers;

ResultFuture<MaterialFile> uploadFile(
  ServerReachabilityService serverReachabilityService,
  LearningMaterialLocalDataSource localDataSource,
  LearningMaterialRemoteDataSource remoteDataSource, {
  required String materialId,
  required String filePath,
  required String fileName,
  void Function(int sent, int total)? onSendProgress,
}) async {
  try {
    if (!serverReachabilityService.isServerReachable) {
      final mime = helpers.mimeType(filePath);
      final size = await helpers.fileSize(filePath);

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
      onSendProgress: onSendProgress,
    );

    try {
      RepoLogger.instance.log('uploadFile() - File uploaded successfully, fetching material detail...');
      final materialDetail = await remoteDataSource.getMaterialDetail(materialId: materialId);
      RepoLogger.instance.log('uploadFile() - Got material detail: ${materialDetail.files.length} files');

      if (materialDetail.files.isNotEmpty) {
        RepoLogger.instance.log('uploadFile() - Caching ${materialDetail.files.length} files to local DB...');
        await localDataSource.cacheMaterialFiles(materialId, materialDetail.files);
        RepoLogger.instance.log('uploadFile() - Cache complete, notifying event bus...');
      } else {
        RepoLogger.instance.warn('uploadFile() - No files in response, skipping cache');
      }
    } catch (e) {
      RepoLogger.instance.error('uploadFile() - Error during post-upload caching', e);
    }

    return Right(result);
  } on ServerException catch (e) {
    return Left(ServerFailure(e.message, statusCode: e.statusCode));
  } on NetworkException catch (e) {
    return Left(NetworkFailure(e.message));
  } catch (e) {
    return Left(ServerFailure(e.toString()));
  }
}
