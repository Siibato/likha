import 'package:dartz/dartz.dart';
import 'package:likha/core/errors/exceptions.dart';
import 'package:likha/core/errors/failures.dart';
import 'package:likha/core/utils/typedef.dart';
import 'package:likha/data/datasources/local/classes/class_local_datasource.dart';
import 'package:likha/data/datasources/remote/classes/class_remote_datasource.dart';
import 'package:likha/domain/auth/entities/user.dart';

ResultFuture<List<User>> searchStudents(
  ClassLocalDataSource localDataSource,
  ClassRemoteDataSource remoteDataSource, {
  String? query,
}) async {
  try {
    final result = await remoteDataSource.searchStudents(query: query);

    try {
      await localDataSource.cacheSearchStudents(result);
    } catch (_) {
      // Caching failure must not block the online result
    }

    return Right(result);
  } on ServerException catch (e) {
    return Left(ServerFailure(e.message));
  } on NetworkException catch (e) {
    try {
      final cached = await localDataSource.searchCachedStudents(query ?? '');
      return Right(cached);
    } catch (_) {
      // Fall through to network error
    }
    return Left(NetworkFailure(e.message));
  } catch (e) {
    return Left(ServerFailure(e.toString()));
  }
}
