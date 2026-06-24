import 'package:likha/core/sync/mutation_result.dart';
import 'package:likha/core/sync/sync_queue.dart';
import 'package:likha/core/utils/typedef.dart';
import 'package:likha/data/datasources/local/setup/setup_local_datasource.dart';
import 'package:likha/data/datasources/remote/setup/setup_remote_datasource.dart';
import 'package:likha/domain/setup/entities/school_details.dart';
import 'package:likha/domain/setup/repositories/setup_repository.dart';
import 'operations/get_school_details.dart' as ops_get;
import 'operations/update_school_details.dart' as ops_update;
import 'operations/update_school_code.dart' as ops_code;

class SetupRepositoryImpl implements SetupRepository {
  final SetupRemoteDataSource _remoteDataSource;
  final SetupLocalDataSource _localDataSource;
  final SyncQueue _syncQueue;

  SetupRepositoryImpl({
    required SetupRemoteDataSource remoteDataSource,
    required SetupLocalDataSource localDataSource,
    required SyncQueue syncQueue,
  })  : _remoteDataSource = remoteDataSource,
        _localDataSource = localDataSource,
        _syncQueue = syncQueue;

  @override
  ResultFuture<SchoolDetails> getSchoolDetails({bool skipBackgroundRefresh = false}) =>
      ops_get.getSchoolDetails(
        _localDataSource,
        _remoteDataSource,
        skipBackgroundRefresh: skipBackgroundRefresh,
      );

  @override
  ResultFuture<MutationResult<SchoolDetails>> updateSchoolDetails({
    required String schoolName,
    required String schoolRegion,
    required String schoolDivision,
    required String schoolYear,
    required String schoolCode,
    String? schoolDistrict,
    String? schoolHeadName,
    String? schoolHeadPosition,
  }) =>
      ops_update.updateSchoolDetails(
        _localDataSource,
        _syncQueue,
        schoolName: schoolName,
        schoolRegion: schoolRegion,
        schoolDivision: schoolDivision,
        schoolYear: schoolYear,
        schoolCode: schoolCode,
        schoolDistrict: schoolDistrict,
        schoolHeadName: schoolHeadName,
        schoolHeadPosition: schoolHeadPosition,
      );

  @override
  ResultFuture<MutationResult<SchoolDetails>> updateSchoolCode({
    required String schoolCode,
  }) =>
      ops_code.updateSchoolCode(
        _localDataSource,
        _syncQueue,
        schoolCode: schoolCode,
      );
}
