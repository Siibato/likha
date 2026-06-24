import 'package:dartz/dartz.dart';
import 'package:likha/core/errors/exceptions.dart';
import 'package:likha/core/errors/failures.dart';
import 'package:likha/core/utils/remote_fetch.dart';
import 'package:likha/core/utils/typedef.dart';
import 'package:likha/data/datasources/local/grading/grading_local_datasource.dart';
import 'package:likha/data/datasources/remote/grading/grading_remote_datasource.dart';
import 'package:likha/domain/grading/entities/grade_score.dart';

import '_helpers.dart' as helpers;

ResultFuture<List<GradeScore>> getScoresByItem(
  GradingLocalDataSource localDataSource,
  GradingRemoteDataSource remoteDataSource, {
  required String gradeItemId,
}) async {
  try {
    try {
      final cached = await localDataSource.getScoresByItem(gradeItemId);

      fireRemoteFetch(
        dedupKey: 'grading/scores/$gradeItemId/bg',
        remote: () => remoteDataSource.getScoresByItem(gradeItemId: gradeItemId),
        onSuccess: (fresh) async {
          try {
            final current = await localDataSource.getScoresByItem(gradeItemId);
            if (current.length != fresh.length) {
              await localDataSource.saveScores(fresh);
              return;
            }
            final currentById = {for (final c in current) c.id: c};
            for (final f in fresh) {
              final c = currentById[f.id];
              if (c == null ||
                  c.score != f.score ||
                  c.overrideScore != f.overrideScore ||
                  c.isAutoPopulated != f.isAutoPopulated) {
                await localDataSource.saveScores(fresh);
                return;
              }
            }
          } catch (_) {
            await localDataSource.saveScores(fresh);
          }
        },
      );

      return Right(cached.map(helpers.scoreToEntity).toList());
    } on CacheException {
      final fresh = await remoteFetch(
        dedupKey: 'grading/scores/$gradeItemId',
        remote: () => remoteDataSource.getScoresByItem(gradeItemId: gradeItemId),
      );
      await localDataSource.saveScores(fresh);
      return Right(fresh.map(helpers.scoreToEntity).toList());
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
