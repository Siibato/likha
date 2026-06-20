import 'package:dartz/dartz.dart';
import 'package:likha/core/errors/exceptions.dart';
import 'package:likha/core/errors/failures.dart';
import 'package:likha/core/events/data_event_bus.dart';
import 'package:likha/core/sync/sync_queue.dart';
import 'package:likha/core/utils/remote_fetch.dart';
import 'package:likha/core/utils/typedef.dart';
import 'package:likha/data/datasources/local/setup/setup_local_datasource.dart';
import 'package:likha/data/datasources/remote/setup/setup_remote_datasource.dart';
import 'package:likha/data/models/setup/school_details_model.dart';
import 'package:likha/domain/setup/entities/school_details.dart';

ResultFuture<SchoolDetails> getSchoolDetails(
  SetupLocalDataSource localDataSource,
  SetupRemoteDataSource remoteDataSource,
  DataEventBus dataEventBus, {
  bool skipBackgroundRefresh = false,
}) async {
  try {
    try {
      final cached = await localDataSource.getCachedSchoolDetails();

      if (!skipBackgroundRefresh) {
        fireRemoteFetch(
          dedupKey: 'setup/schoolDetails/bg',
          remote: remoteDataSource.getSchoolDetails,
          onSuccess: (fresh) async {
            try {
              final current = await localDataSource.getCachedSchoolDetails();
              // Skip overwriting pending local changes with stale server data.
              // The sync engine will reconcile after the pending update completes.
              if (current.syncStatus == SyncStatus.pending) return;
              if (_settingsHaveChanged(current, fresh)) {
                await localDataSource.cacheSchoolDetails(fresh);
                dataEventBus.notifySchoolDetailsChanged();
              }
            } on CacheException {
              await localDataSource.cacheSchoolDetails(fresh);
              dataEventBus.notifySchoolDetailsChanged();
            }
          },
        );
      }
      return Right(cached);
    } on CacheException {
      final fresh = await remoteFetch(
        dedupKey: 'setup/schoolDetails',
        remote: remoteDataSource.getSchoolDetails,
      );
      await localDataSource.cacheSchoolDetails(fresh);
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

bool _settingsHaveChanged(
  SchoolDetailsModel current,
  SchoolDetailsModel fresh,
) {
  return current.schoolName != fresh.schoolName ||
      current.schoolRegion != fresh.schoolRegion ||
      current.schoolDivision != fresh.schoolDivision ||
      current.schoolYear != fresh.schoolYear ||
      current.schoolCode != fresh.schoolCode;
}
