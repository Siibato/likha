import 'package:dartz/dartz.dart';
import 'package:likha/core/errors/failures.dart';
import 'package:likha/core/utils/typedef.dart';
import 'package:likha/data/datasources/remote/grading/grading_remote_datasource.dart';
import 'package:likha/domain/grading/entities/sf9.dart';

ResultFuture<Sf9Response> getSf9(
  GradingRemoteDataSource remoteDataSource, {
  required String classId,
  required String studentId,
}) async {
  try {
    final model = await remoteDataSource.getSf9(
      classId: classId,
      studentId: studentId,
    );
    return Right(model);
  } on ServerFailure catch (e) {
    return Left(e);
  } on Failure catch (e) {
    return Left(e);
  } catch (e) {
    return Left(ServerFailure(e.toString()));
  }
}
