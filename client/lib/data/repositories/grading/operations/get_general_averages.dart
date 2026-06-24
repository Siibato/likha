import 'dart:convert';

import 'package:dartz/dartz.dart';
import 'package:likha/core/errors/exceptions.dart';
import 'package:likha/core/errors/failures.dart';
import 'package:likha/core/utils/remote_fetch.dart';
import 'package:likha/core/utils/typedef.dart';
import 'package:likha/data/datasources/local/grading/grading_local_datasource.dart';
import 'package:likha/data/datasources/local/grading/operations/assemble_general_averages_local.dart';
import 'package:likha/data/datasources/remote/grading/grading_remote_datasource.dart';
import 'package:likha/data/models/grading/general_average_model.dart';
import 'package:likha/domain/grading/entities/general_average.dart';

ResultFuture<GeneralAverageResponse> getGeneralAverages(
  GradingLocalDataSource localDataSource,
  GradingRemoteDataSource remoteDataSource, {
  required String classId,
}) async {
  try {
    // 1. Try local assembly from synced DB tables first
    try {
      final assembled = await assembleGeneralAveragesLocal(
        localDataSource.localDatabase,
        classId,
      );

      if (assembled != null) {
        final hasRealStudents = assembled.students.any(
          (s) => s.studentName != 'Unknown Student',
        );
        if (hasRealStudents) {
          fireRemoteFetch(
            dedupKey: 'grading/generalAverages/$classId/bg',
            remote: () => remoteDataSource.getGeneralAverages(classId: classId),
            onSuccess: (fresh) async {
              try {
                final current = await localDataSource.getCachedGeneralAverages(classId);
                if (_generalAveragesHaveChanged(current, fresh.toJson())) {
                  await localDataSource.cacheGeneralAverages(classId, fresh.toJson());
                }
              } catch (_) {
                await localDataSource.cacheGeneralAverages(classId, fresh.toJson());
              }
            },
          );

          return Right(assembled);
        }
      }
    } catch (_) {
      // Local assembly failed, fall through to cache
    }

    // 2. Fall back to syncMetadata cache
    try {
      final cached = await localDataSource.getCachedGeneralAverages(classId);

      if (cached.isEmpty) {
        throw CacheException('No cached general averages found');
      }

      final students = cached['students'] as List<dynamic>? ?? [];
      if (students.isEmpty) {
        throw CacheException('Cached general averages has empty students');
      }
      final allUnknown = students.isNotEmpty && students.every(
        (s) => (s as Map<String, dynamic>)['student_name'] == 'Unknown Student',
      );
      if (allUnknown) {
        throw CacheException('Cached general averages has stale unknown students');
      }

      fireRemoteFetch(
        dedupKey: 'grading/generalAverages/$classId/bg',
        remote: () => remoteDataSource.getGeneralAverages(classId: classId),
        onSuccess: (fresh) async {
          try {
            final current = await localDataSource.getCachedGeneralAverages(classId);
            if (_generalAveragesHaveChanged(current, fresh.toJson())) {
              await localDataSource.cacheGeneralAverages(classId, fresh.toJson());
            }
          } catch (_) {
            await localDataSource.cacheGeneralAverages(classId, fresh.toJson());
          }
        },
      );

      return Right(GeneralAverageResponseModel.fromJson(cached));
    } on CacheException {
      // 3. Fall back to blocking remote fetch
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
  return jsonEncode(current) != jsonEncode(fresh);
}
