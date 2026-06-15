import 'package:dartz/dartz.dart';
import 'package:likha/core/errors/exceptions.dart';
import 'package:likha/core/errors/failures.dart';
import 'package:likha/core/events/data_event_bus.dart';
import 'package:likha/core/utils/remote_fetch.dart';
import 'package:likha/core/utils/typedef.dart';
import 'package:likha/data/datasources/local/grading/grading_local_datasource.dart';
import 'package:likha/data/datasources/remote/grading/grading_remote_datasource.dart';
import 'package:likha/data/models/grading/general_average_model.dart';
import 'package:likha/domain/grading/entities/general_average.dart';

ResultFuture<GeneralAverageResponse> getGeneralAverages(
  GradingLocalDataSource localDataSource,
  GradingRemoteDataSource remoteDataSource,
  DataEventBus dataEventBus, {
  required String classId,
}) async {
  try {
    try {
      final cached = await localDataSource.getCachedGeneralAverages(classId);

      // Treat empty map as cache miss
      if (cached.isEmpty) {
        throw CacheException('No cached general averages found');
      }

      fireRemoteFetch(
        dedupKey: 'grading/generalAverages/$classId/bg',
        remote: () => remoteDataSource.getGeneralAverages(classId: classId),
        onSuccess: (fresh) async {
          try {
            final current = await localDataSource.getCachedGeneralAverages(classId);
            if (_generalAveragesHaveChanged(current, fresh.toJson())) {
              await localDataSource.cacheGeneralAverages(classId, fresh.toJson());
              dataEventBus.notifyGeneralAveragesChanged(classId);
            }
          } catch (_) {
            await localDataSource.cacheGeneralAverages(classId, fresh.toJson());
            dataEventBus.notifyGeneralAveragesChanged(classId);
          }
        },
      );

      return Right(GeneralAverageResponseModel.fromJson(cached));
    } on CacheException {
      final fresh = await remoteFetch(
        dedupKey: 'grading/generalAverages/$classId',
        remote: () => remoteDataSource.getGeneralAverages(classId: classId),
      );
      await localDataSource.cacheGeneralAverages(classId, fresh.toJson());
      return Right(fresh);
    }
  } on ServerException catch (e) {
    return Left(ServerFailure(e.message, statusCode: e.statusCode));
  } on NetworkException catch (e) {
    return Left(NetworkFailure(e.message));
  } on CacheException catch (e) {
    return Left(CacheFailure(e.message));
  } catch (e) {
    return Left(ServerFailure(e.toString()));
  }
}

bool _generalAveragesHaveChanged(
  Map<String, dynamic> current,
  Map<String, dynamic> fresh,
) {
  return current.length != fresh.length ||
      current.keys.any((k) => current[k].toString() != fresh[k].toString());
}
