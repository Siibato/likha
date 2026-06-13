import 'package:dartz/dartz.dart';
import 'package:likha/core/errors/failures.dart';
import 'package:likha/core/utils/typedef.dart';
import 'package:likha/data/datasources/remote/grading/grading_remote_datasource.dart';

ResultFuture<List<Map<String, dynamic>>> getFinalGrades(
  GradingRemoteDataSource remoteDataSource, {
  required String classId,
}) async {
  try {
    final grades = await remoteDataSource.getFinalGrades(classId: classId);
    return Right(grades);
  } on ServerFailure catch (e) {
    return Left(e);
  } on Failure catch (e) {
    return Left(e);
  } catch (e) {
    return Left(ServerFailure(e.toString()));
  }
}
