import 'package:dartz/dartz.dart';
import 'package:likha/core/errors/exceptions.dart';
import 'package:likha/core/errors/failures.dart';
import 'package:likha/core/utils/typedef.dart';
import 'package:likha/data/datasources/remote/auth/auth_remote_datasource.dart';
import 'package:likha/domain/auth/entities/user.dart';

ResultFuture<User> activateAccount(
  AuthRemoteDataSource remoteDataSource, {
  required String username,
  required String password,
  required String confirmPassword,
}) async {
  try {
    final result = await remoteDataSource.activateAccount(
      username: username,
      password: password,
      confirmPassword: confirmPassword,
    );
    return Right(result.user);
  } on ServerException catch (e) {
    return Left(ServerFailure(e.message, statusCode: e.statusCode));
  } on NetworkException catch (e) {
    return Left(NetworkFailure(e.message));
  } catch (e) {
    return Left(ServerFailure(e.toString()));
  }
}
