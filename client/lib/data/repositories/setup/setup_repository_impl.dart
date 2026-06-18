import 'package:likha/core/events/data_event_bus.dart';
import 'package:likha/core/sync/mutation_result.dart';
import 'package:likha/core/sync/sync_queue.dart';
import 'package:likha/core/utils/typedef.dart';
import 'package:likha/data/datasources/local/setup/setup_local_datasource.dart';
import 'package:likha/data/datasources/remote/setup/setup_remote_datasource.dart';
import 'package:likha/domain/setup/entities/school_settings.dart';
import 'package:likha/domain/setup/repositories/setup_repository.dart';
import 'operations/get_school_settings.dart' as ops_get;
import 'operations/update_school_settings.dart' as ops_update;
import 'operations/update_school_code.dart' as ops_code;

class SetupRepositoryImpl implements SetupRepository {
  final SetupRemoteDataSource _remoteDataSource;
  final SetupLocalDataSource _localDataSource;
  final SyncQueue _syncQueue;
  final DataEventBus _dataEventBus;

  SetupRepositoryImpl({
    required SetupRemoteDataSource remoteDataSource,
    required SetupLocalDataSource localDataSource,
    required SyncQueue syncQueue,
    required DataEventBus dataEventBus,
  })  : _remoteDataSource = remoteDataSource,
        _localDataSource = localDataSource,
        _syncQueue = syncQueue,
        _dataEventBus = dataEventBus;

  @override
  ResultFuture<SchoolSettings> getSchoolSettings({bool skipBackgroundRefresh = false}) =>
      ops_get.getSchoolSettings(
        _localDataSource,
        _remoteDataSource,
        _dataEventBus,
        skipBackgroundRefresh: skipBackgroundRefresh,
      );

  @override
  ResultFuture<MutationResult<SchoolSettings>> updateSchoolSettings({
    required String schoolName,
    required String schoolRegion,
    required String schoolDivision,
    required String schoolYear,
    required String schoolCode,
    String? schoolDistrict,
  }) =>
      ops_update.updateSchoolSettings(
        _localDataSource,
        _syncQueue,
        schoolName: schoolName,
        schoolRegion: schoolRegion,
        schoolDivision: schoolDivision,
        schoolYear: schoolYear,
        schoolCode: schoolCode,
        schoolDistrict: schoolDistrict,
      );

  @override
  ResultFuture<MutationResult<SchoolSettings>> updateSchoolCode({
    required String schoolCode,
  }) =>
      ops_code.updateSchoolCode(
        _localDataSource,
        _syncQueue,
        schoolCode: schoolCode,
      );
}
