import 'package:dartz/dartz.dart';
import 'package:likha/core/errors/exceptions.dart';
import 'package:likha/core/errors/failures.dart';
import 'package:likha/core/logging/repo_logger.dart';
import 'package:likha/core/utils/typedef.dart';
import 'package:likha/data/datasources/local/learning_materials/learning_material_local_datasource.dart';
import 'package:likha/data/datasources/remote/learning_materials/learning_material_remote_datasource.dart';

ResultFuture<List<int>> downloadFile(
  LearningMaterialLocalDataSource localDataSource,
  LearningMaterialRemoteDataSource remoteDataSource, {
  required String fileId,
}) async {
  try {
    if (await localDataSource.isFileCached(fileId)) {
      final cachedFile = await localDataSource.getCachedFile(fileId);
      return Right(cachedFile);
    }

    final result = await remoteDataSource.downloadFile(fileId: fileId);

    try {
      RepoLogger.instance.log('downloadFile() - Downloaded ${result.length} bytes, caching...');
      // Pass empty fileName to let datasource look it up from material_files table
      await localDataSource.cacheFile(fileId, '', result);
      RepoLogger.instance.log('downloadFile() - File cached successfully');
    } catch (e) {
      // Log the error but still return file — user can open it from memory
      // Next app start: file won't be cached, will need re-download
      RepoLogger.instance.warn('downloadFile() - Cache write failed, file still available in memory', e);
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
