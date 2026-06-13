import 'package:dartz/dartz.dart';
import 'package:likha/core/errors/exceptions.dart';
import 'package:likha/core/errors/failures.dart';
import 'package:likha/core/utils/typedef.dart';
import 'package:likha/data/datasources/local/assignments/assignment_local_datasource.dart';
import 'package:likha/data/datasources/remote/assignments/assignment_remote_datasource.dart';

ResultFuture<List<int>> downloadFile(
  AssignmentLocalDataSource localDataSource,
  AssignmentRemoteDataSource remoteDataSource, {required String fileId}) async {
  try {
    if (await localDataSource.isFileCached(fileId)) {
      final cachedBytes = await localDataSource.getCachedFileBytes(fileId);
      return Right(cachedBytes);
    }

    final result = await remoteDataSource.downloadFile(fileId: fileId);
    // Pass empty fileName to let datasource look it up from submission_files table
    await localDataSource.cacheFileBytes(fileId, '', result);
    return Right(result);
  } on ServerException catch (e) {
    return Left(ServerFailure(e.message, statusCode: e.statusCode));
  } on NetworkException catch (e) {
    return Left(NetworkFailure(e.message));
  } catch (e) {
    return Left(ServerFailure(e.toString()));
  }
}
