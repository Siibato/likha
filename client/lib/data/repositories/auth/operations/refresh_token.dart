import 'package:dartz/dartz.dart';
import 'package:likha/core/errors/exceptions.dart';
import 'package:likha/core/errors/failures.dart';
import 'package:likha/core/utils/typedef.dart';
import 'package:likha/data/datasources/remote/auth/auth_remote_datasource.dart';
import 'package:likha/domain/auth/entities/user.dart';
import 'package:likha/services/storage_service.dart';

ResultFuture<User> refreshToken(
  AuthRemoteDataSource remoteDataSource,
  StorageService storageService,
) async {
  try {
    final token = await storageService.getRefreshToken();
    if (token == null) {
      return const Left(UnauthorizedFailure('No refresh token found'));
    }

    final result = await remoteDataSource.refreshToken(token);
    return Right(result.user);
  } on ServerException catch (e) {
    return Left(ServerFailure(e.message, statusCode: e.statusCode));
  } on NetworkException catch (e) {
    return Left(NetworkFailure(e.message));
  } on UnauthorizedException catch (e) {
    return Left(UnauthorizedFailure(e.message));
  } catch (e) {
    return Left(ServerFailure(e.toString()));
  }
}
