import 'package:dartz/dartz.dart';
import 'package:likha/core/errors/failures.dart';
import 'package:likha/core/utils/typedef.dart';
import 'package:likha/data/datasources/remote/grading/grading_remote_datasource.dart';
import 'package:likha/domain/grading/entities/general_average.dart';

ResultFuture<GeneralAverageResponse> getGeneralAverages(
  GradingRemoteDataSource remoteDataSource, {
  required String classId,
}) async {
  try {
    final model = await remoteDataSource.getGeneralAverages(
      classId: classId,
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
