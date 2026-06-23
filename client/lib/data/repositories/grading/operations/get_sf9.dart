import 'dart:convert';

import 'package:dartz/dartz.dart';
import 'package:likha/core/errors/exceptions.dart';
import 'package:likha/core/errors/failures.dart';
import 'package:likha/core/logging/sf9_logger.dart';
import 'package:likha/core/utils/remote_fetch.dart';
import 'package:likha/core/utils/typedef.dart';
import 'package:likha/data/datasources/local/grading/grading_local_datasource.dart';
import 'package:likha/data/datasources/local/grading/operations/assemble_sf9_local.dart';
import 'package:likha/data/datasources/remote/grading/grading_remote_datasource.dart';
import 'package:likha/data/models/grading/sf9_model.dart';
import 'package:likha/domain/grading/entities/sf9.dart';

ResultFuture<Sf9Response> getSf9(
  GradingLocalDataSource localDataSource,
  GradingRemoteDataSource remoteDataSource, {
  required String classId,
  required String studentId,
  bool skipBackgroundRefresh = false,
}) async {
  final log = Sf9Logger.instance;
  log.log('getSf9: START classId=$classId studentId=$studentId');
  try {
    // 1. Try local assembly from synced DB tables first
    try {
      final assembled = await assembleSf9Local(
        localDataSource.localDatabase,
        classId,
        studentId,
      );

      if (assembled != null) {
        log.log('getSf9: LOCAL ASSEMBLY HIT — returning assembled data');

        if (!skipBackgroundRefresh) {
          fireRemoteFetch(
            dedupKey: 'grading/sf9/$classId/$studentId/bg',
            remote: () => remoteDataSource.getSf9(
              classId: classId,
              studentId: studentId,
            ),
            onSuccess: (fresh) async {
              log.log('getSf9: background refresh succeeded, caching result');
              try {
                await localDataSource.cacheSf9(classId, studentId, fresh.toJson());
              } catch (e) {
                log.warn('getSf9: background refresh cache failed', e);
              }
            },
          );
        }

        return Right(assembled);
      }

      log.log('getSf9: LOCAL ASSEMBLY MISS — falling back to syncMetadata cache');
    } catch (e) {
      log.log('getSf9: local assembly error — $e');
    }

    // 2. Fall back to syncMetadata cache (legacy on-demand cache)
    try {
      final cached = await localDataSource.getCachedSf9(classId, studentId);

      if (cached.isEmpty) {
        log.log('getSf9: cache hit but empty map — treating as miss');
        throw CacheException('No cached SF9 found');
      }
      if (cached['student_name'] == 'Unknown Student') {
        log.log('getSf9: cache hit but student_name="Unknown Student" — treating as miss');
        throw CacheException('Cached SF9 has stale unknown student');
      }

      log.log('getSf9: CACHE HIT — returning cached data, firing background refresh');
      if (!skipBackgroundRefresh) {
        fireRemoteFetch(
        dedupKey: 'grading/sf9/$classId/$studentId/bg',
        remote: () => remoteDataSource.getSf9(
          classId: classId,
          studentId: studentId,
        ),
        onSuccess: (fresh) async {
          log.log('getSf9: background refresh succeeded, comparing with cache');
          try {
            final current = await localDataSource.getCachedSf9(classId, studentId);
            if (_sf9HasChanged(current, fresh.toJson())) {
              log.log('getSf9: background refresh detected changes — updating cache');
              await localDataSource.cacheSf9(classId, studentId, fresh.toJson());
            } else {
              log.log('getSf9: background refresh — no changes detected');
            }
          } catch (e) {
            log.warn('getSf9: background refresh comparison failed, writing cache anyway', e);
            await localDataSource.cacheSf9(classId, studentId, fresh.toJson());
          }
        },
      );
      }

      return Right(Sf9ResponseModel.fromJson(cached));
    } on CacheException catch (e) {
      log.log('getSf9: CACHE MISS (${e.message}) — doing blocking remoteFetch');
      try {
        final fresh = await remoteFetch(
          dedupKey: 'grading/sf9/$classId/$studentId',
          remote: () => remoteDataSource.getSf9(
            classId: classId,
            studentId: studentId,
          ),
        );
        log.log('getSf9: remoteFetch succeeded, writing to cache');
        await localDataSource.cacheSf9(classId, studentId, fresh.toJson());
        log.log('getSf9: returning fresh remote data');
        return Right(fresh);
      } on NetworkException catch (e) {
        log.warn('getSf9: remoteFetch failed (offline)', e);
        return Left(NetworkFailure(e.message));
      } on ServerException catch (e) {
        log.warn('getSf9: remoteFetch failed (server)', e);
        return Left(ServerFailure(e.message, statusCode: e.statusCode));
      }
    }
  } on ServerException catch (e) {
    log.error('getSf9: ServerException', e);
    return Left(ServerFailure(e.message, statusCode: e.statusCode));
  } on NetworkException catch (e) {
    log.error('getSf9: NetworkException', e);
    return Left(NetworkFailure(e.message));
  } on CacheException catch (e) {
    log.error('getSf9: CacheException', e);
    return Left(CacheFailure(e.message));
  } catch (e) {
    log.error('getSf9: unexpected error', e);
    return Left(ServerFailure(e.toString()));
  }
}

bool _sf9HasChanged(
  Map<String, dynamic> current,
  Map<String, dynamic> fresh,
) {
  return jsonEncode(current) != jsonEncode(fresh);
}
