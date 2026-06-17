import 'package:dartz/dartz.dart';
import 'package:likha/core/errors/exceptions.dart';
import 'package:likha/core/errors/failures.dart';
import 'package:likha/core/events/data_event_bus.dart';
import 'package:likha/core/sync/sync_queue.dart';
import 'package:likha/core/utils/remote_fetch.dart';
import 'package:likha/core/utils/typedef.dart';
import 'package:likha/data/datasources/local/setup/setup_local_datasource.dart';
import 'package:likha/data/datasources/remote/setup/setup_remote_datasource.dart';
import 'package:likha/data/models/setup/school_settings_model.dart';
import 'package:likha/domain/setup/entities/school_settings.dart';

ResultFuture<SchoolSettings> getSchoolSettings(
  SetupLocalDataSource localDataSource,
  SetupRemoteDataSource remoteDataSource,
  DataEventBus dataEventBus, {
  bool skipBackgroundRefresh = false,
}) async {
  try {
    try {
      final cached = await localDataSource.getCachedSchoolSettings();

      if (!skipBackgroundRefresh) {
        fireRemoteFetch(
          dedupKey: 'setup/schoolSettings/bg',
          remote: remoteDataSource.getSchoolSettings,
          onSuccess: (fresh) async {
            try {
              final current = await localDataSource.getCachedSchoolSettings();
              // Skip overwriting pending local changes with stale server data.
              // The sync engine will reconcile after the pending update completes.
              if (current.syncStatus == SyncStatus.pending) return;
              if (_settingsHaveChanged(current, fresh)) {
                await localDataSource.cacheSchoolSettings(fresh);
                dataEventBus.notifySchoolSettingsChanged();
              }
            } on CacheException {
              await localDataSource.cacheSchoolSettings(fresh);
              dataEventBus.notifySchoolSettingsChanged();
            }
          },
        );
      }
      return Right(cached);
    } on CacheException {
      final fresh = await remoteFetch(
        dedupKey: 'setup/schoolSettings',
        remote: remoteDataSource.getSchoolSettings,
      );
      await localDataSource.cacheSchoolSettings(fresh);
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
  SchoolSettingsModel current,
  SchoolSettingsModel fresh,
) {
  return current.schoolName != fresh.schoolName ||
      current.schoolRegion != fresh.schoolRegion ||
      current.schoolDivision != fresh.schoolDivision ||
      current.schoolYear != fresh.schoolYear ||
      current.schoolCode != fresh.schoolCode;
}
