import 'package:dartz/dartz.dart';
import 'package:likha/core/errors/exceptions.dart';
import 'package:likha/core/errors/failures.dart';
import 'package:likha/core/events/data_event_bus.dart';
import 'package:likha/core/utils/remote_fetch.dart';
import 'package:likha/core/utils/typedef.dart';
import 'package:likha/data/datasources/local/grading/grading_local_datasource.dart';
import 'package:likha/data/datasources/remote/grading/grading_remote_datasource.dart';

ResultFuture<List<Map<String, dynamic>>> getFinalGrades(
  GradingLocalDataSource localDataSource,
  GradingRemoteDataSource remoteDataSource,
  DataEventBus dataEventBus, {
  required String classId,
}) async {
  try {
    try {
      final cached = await localDataSource.getCachedFinalGrades(classId);

      // Treat empty list as cache miss
      if (cached.isEmpty) {
        throw CacheException('No cached final grades found');
      }

      fireRemoteFetch(
        dedupKey: 'grading/finalGrades/$classId/bg',
        remote: () => remoteDataSource.getFinalGrades(classId: classId),
        onSuccess: (fresh) async {
          try {
            final current = await localDataSource.getCachedFinalGrades(classId);
            if (_finalGradesHaveChanged(current, fresh)) {
              await localDataSource.cacheFinalGrades(classId, fresh);
              dataEventBus.notifyFinalGradesChanged(classId);
            }
          } catch (_) {
            await localDataSource.cacheFinalGrades(classId, fresh);
            dataEventBus.notifyFinalGradesChanged(classId);
          }
        },
      );

      return Right(cached);
    } on CacheException {
      final fresh = await remoteFetch(
        dedupKey: 'grading/finalGrades/$classId',
        remote: () => remoteDataSource.getFinalGrades(classId: classId),
      );
      await localDataSource.cacheFinalGrades(classId, fresh);
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

bool _finalGradesHaveChanged(
  List<Map<String, dynamic>> current,
  List<Map<String, dynamic>> fresh,
) {
  if (current.length != fresh.length) return true;
  final currentIds = {for (final c in current) c['student_id'] ?? c['id'] ?? ''};
  final freshIds = {for (final f in fresh) f['student_id'] ?? f['id'] ?? ''};
  if (currentIds.length != freshIds.length || currentIds.difference(freshIds).isNotEmpty) {
    return true;
  }
  return false;
}
