import 'package:dartz/dartz.dart';
import 'package:likha/core/errors/exceptions.dart';
import 'package:likha/core/errors/failures.dart';
import 'package:likha/core/utils/remote_fetch.dart';
import 'package:likha/core/utils/typedef.dart';
import 'package:likha/data/datasources/local/grading/grading_local_datasource.dart';
import 'package:likha/data/datasources/remote/grading/grading_remote_datasource.dart';

ResultFuture<List<Map<String, dynamic>>> getGradeSummary(
  GradingLocalDataSource localDataSource,
  GradingRemoteDataSource remoteDataSource, {
  required String classId,
  required int termNumber,
}) async {
  try {
    try {
      final cached = await localDataSource.getCachedGradeSummary(classId, termNumber);

      fireRemoteFetch(
        dedupKey: 'grading/summary/$classId/$termNumber/bg',
        remote: () => remoteDataSource.getGradeSummary(
          classId: classId,
          termNumber: termNumber,
        ),
        onSuccess: (fresh) async {
          try {
            final current = await localDataSource.getCachedGradeSummary(classId, termNumber);
            if (!_summariesEqual(current, fresh)) {
              await localDataSource.cacheGradeSummary(classId, termNumber, fresh);
            }
          } catch (_) {
            await localDataSource.cacheGradeSummary(classId, termNumber, fresh);
          }
        },
      );

      return Right(cached);
    } on CacheException {
      final fresh = await remoteFetch(
        dedupKey: 'grading/summary/$classId/$termNumber',
        remote: () => remoteDataSource.getGradeSummary(
          classId: classId,
          termNumber: termNumber,
        ),
      );
      await localDataSource.cacheGradeSummary(classId, termNumber, fresh);
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

bool _summariesEqual(List<Map<String, dynamic>> a, List<Map<String, dynamic>> b) {
  if (a.length != b.length) return false;
  final bById = {for (final item in b) item['student_id'] ?? item['id']: item};
  for (final item in a) {
    final key = item['student_id'] ?? item['id'];
    final match = bById[key];
    if (match == null) return false;
  }
  return true;
}
