import 'package:dartz/dartz.dart';
import 'package:likha/core/errors/exceptions.dart';
import 'package:likha/core/errors/failures.dart';
import 'package:likha/core/events/data_event_bus.dart';
import 'package:likha/core/utils/remote_fetch.dart';
import 'package:likha/core/utils/typedef.dart';
import 'package:likha/data/datasources/local/grading/grading_local_datasource.dart';
import 'package:likha/data/datasources/remote/grading/grading_remote_datasource.dart';
import 'package:likha/domain/grading/entities/period_grade.dart';

import '_helpers.dart' as helpers;

ResultFuture<List<PeriodGrade>> getMyGrades(
  GradingLocalDataSource localDataSource,
  GradingRemoteDataSource remoteDataSource,
  DataEventBus dataEventBus, {
  required String classId,
}) async {
  try {
    try {
      final cached = await localDataSource.getPeriodGradesByClass(classId, 0);

      fireRemoteFetch(
        dedupKey: 'grading/myGrades/$classId/bg',
        remote: () => remoteDataSource.getMyGrades(classId: classId),
        onSuccess: (fresh) async {
          try {
            final current = await localDataSource.getPeriodGradesByClass(classId, 0);
            if (current.length != fresh.length) {
              await localDataSource.savePeriodGrades(fresh);
              dataEventBus.notifyGradesChanged(classId);
              return;
            }
            final currentById = {for (final c in current) c.id: c};
            for (final f in fresh) {
              final c = currentById[f.id];
              if (c == null ||
                  c.initialGrade != f.initialGrade ||
                  c.transmutedGrade != f.transmutedGrade ||
                  c.isLocked != f.isLocked) {
                await localDataSource.savePeriodGrades(fresh);
                dataEventBus.notifyGradesChanged(classId);
                return;
              }
            }
          } catch (_) {
            await localDataSource.savePeriodGrades(fresh);
            dataEventBus.notifyGradesChanged(classId);
          }
        },
      );

      return Right(cached.map(helpers.periodToEntity).toList());
    } on CacheException {
      final fresh = await remoteFetch(
        dedupKey: 'grading/myGrades/$classId',
        remote: () => remoteDataSource.getMyGrades(classId: classId),
      );
      await localDataSource.savePeriodGrades(fresh);
      return Right(fresh.map(helpers.periodToEntity).toList());
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
