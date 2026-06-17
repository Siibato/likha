import 'dart:convert';

import 'package:dartz/dartz.dart';
import 'package:likha/core/errors/exceptions.dart';
import 'package:likha/core/errors/failures.dart';
import 'package:likha/core/events/data_event_bus.dart';
import 'package:likha/core/utils/remote_fetch.dart';
import 'package:likha/core/utils/typedef.dart';
import 'package:likha/data/datasources/local/grading/grading_local_datasource.dart';
import 'package:likha/data/datasources/remote/grading/grading_remote_datasource.dart';
import 'package:likha/data/models/grading/sf9_model.dart';
import 'package:likha/domain/grading/entities/sf9.dart';

ResultFuture<Sf9Response> getSf10(
  GradingLocalDataSource localDataSource,
  GradingRemoteDataSource remoteDataSource,
  DataEventBus dataEventBus, {
  required String classId,
  required String studentId,
}) async {
  try {
    try {
      final cached = await localDataSource.getCachedSf10(classId, studentId);

      // Treat empty map or stale unknown-student as cache miss
      if (cached.isEmpty) {
        throw CacheException('No cached SF10 found');
      }
      if (cached['student_name'] == 'Unknown Student') {
        throw CacheException('Cached SF10 has stale unknown student');
      }

      fireRemoteFetch(
        dedupKey: 'grading/sf10/$classId/$studentId/bg',
        remote: () => remoteDataSource.getSf10(
          classId: classId,
          studentId: studentId,
        ),
        onSuccess: (fresh) async {
          try {
            final current = await localDataSource.getCachedSf10(classId, studentId);
            if (_sf10HasChanged(current, fresh.toJson())) {
              await localDataSource.cacheSf10(classId, studentId, fresh.toJson());
              dataEventBus.notifySf10Changed(classId);
            }
          } catch (_) {
            await localDataSource.cacheSf10(classId, studentId, fresh.toJson());
            dataEventBus.notifySf10Changed(classId);
          }
        },
      );

      return Right(Sf9ResponseModel.fromJson(cached));
    } on CacheException {
      final fresh = await remoteFetch(
        dedupKey: 'grading/sf10/$classId/$studentId',
        remote: () => remoteDataSource.getSf10(
          classId: classId,
          studentId: studentId,
        ),
      );
      await localDataSource.cacheSf10(classId, studentId, fresh.toJson());
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

bool _sf10HasChanged(
  Map<String, dynamic> current,
  Map<String, dynamic> fresh,
) {
  return jsonEncode(current) != jsonEncode(fresh);
}
