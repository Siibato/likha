import 'package:dartz/dartz.dart';
import 'package:likha/core/errors/exceptions.dart';
import 'package:likha/core/errors/failures.dart';
import 'package:likha/core/utils/remote_fetch.dart';
import 'package:likha/core/utils/typedef.dart';
import 'package:likha/data/datasources/local/tos/tos_local_datasource.dart';
import 'package:likha/data/datasources/remote/tos/tos_remote_datasource.dart';
import 'package:likha/data/models/tos/melcs_model.dart';

bool _melcsHaveChanged(List<MelcEntryModel> current, List<MelcEntryModel> fresh) {
  if (current.length != fresh.length) return true;
  final currentIds = current.map((e) => e.id).toSet();
  final freshIds = fresh.map((e) => e.id).toSet();
  return !currentIds.containsAll(freshIds) || !freshIds.containsAll(currentIds);
}

ResultFuture<List<MelcEntryModel>> searchMelcs(
  TosLocalDataSource localDataSource,
  TosRemoteDataSource remoteDataSource, {
  String? subject,
  String? gradeLevel,
  int? termNumber,
  String? query,
  int limit = 30,
  int offset = 0,
  bool skipBackgroundRefresh = false,
}) async {
  try {
    try {
      final cached = await localDataSource.searchMelcs(
        subject: subject,
        gradeLevel: gradeLevel,
        termNumber: termNumber,
        query: query,
        limit: limit,
        offset: offset,
      );

      if (!skipBackgroundRefresh) {
        fireRemoteFetch(
          dedupKey: 'tos/searchMelcs/${subject ?? 'all'}/${gradeLevel ?? 'all'}/${termNumber ?? 'all'}/${query ?? 'all'}/bg',
          remote: () => remoteDataSource.searchMelcs(
            subject: subject,
            gradeLevel: gradeLevel,
            termNumber: termNumber,
            query: query,
            limit: limit,
            offset: offset,
          ),
          onSuccess: (fresh) async {
            final current = await localDataSource.searchMelcs(
              subject: subject,
              gradeLevel: gradeLevel,
              termNumber: termNumber,
              query: query,
              limit: limit,
              offset: offset,
            );
            if (_melcsHaveChanged(current, fresh)) {
              await localDataSource.cacheMelcs(fresh);
            }
          },
        );
      }

      return Right(cached);
    } on CacheException {
      final fresh = await remoteFetch(
        dedupKey: 'tos/searchMelcs/${subject ?? 'all'}/${gradeLevel ?? 'all'}/${termNumber ?? 'all'}/${query ?? 'all'}',
        remote: () => remoteDataSource.searchMelcs(
          subject: subject,
          gradeLevel: gradeLevel,
          termNumber: termNumber,
          query: query,
          limit: limit,
          offset: offset,
        ),
      );
      try {
        await localDataSource.cacheMelcs(fresh);
      } catch (_) {
        // Caching failure must not block the online result
      }
      return Right(fresh);
    }
  } on ServerException catch (e) {
    return Left(ServerFailure(e.message));
  } on NetworkException catch (e) {
    return Left(NetworkFailure(e.message));
  } catch (e) {
    return Left(ServerFailure(e.toString()));
  }
}
