import 'package:dartz/dartz.dart';
import 'package:likha/core/errors/exceptions.dart';
import 'package:likha/core/errors/failures.dart';
import 'package:likha/core/utils/typedef.dart';
import 'package:likha/data/datasources/local/classes/class_local_datasource.dart';
import 'package:likha/domain/auth/entities/user.dart';

ResultFuture<List<User>> getParticipants(
  ClassLocalDataSource localDataSource, {
  required String classId,
}) async {
  try {
    final students = await localDataSource.getCachedParticipants(classId);
    return Right(students.cast<User>());
  } on CacheException catch (e) {
    return Left(CacheFailure(e.message));
  } catch (e) {
    return Left(ServerFailure(e.toString()));
  }
}
