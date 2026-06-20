import 'package:likha/core/database/local_database.dart';
import 'package:likha/core/sync/sync_queue.dart';
import 'package:likha/data/models/setup/school_details_model.dart';
import 'operations/setup.dart' as ops;

abstract class SetupLocalDataSource {
  LocalDatabase get localDatabase;

  Future<SchoolDetailsModel> getCachedSchoolDetails();
  Future<void> cacheSchoolDetails(SchoolDetailsModel settings);
  Future<void> updateSchoolDetailsLocally({
    required String schoolName,
    required String schoolRegion,
    required String schoolDivision,
    required String schoolYear,
    required String schoolCode,
    String? schoolDistrict,
    String? schoolHeadName,
    String? schoolHeadPosition,
    SyncStatus syncStatus,
    Transaction? txn,
  });
}

class SetupLocalDataSourceImpl implements SetupLocalDataSource {
  @override
  final LocalDatabase localDatabase;
  final SyncQueue syncQueue;

  SetupLocalDataSourceImpl(this.localDatabase, this.syncQueue);

  @override
  Future<SchoolDetailsModel> getCachedSchoolDetails() =>
      ops.getCachedSchoolDetails(localDatabase);

  @override
  Future<void> cacheSchoolDetails(SchoolDetailsModel settings) =>
      ops.cacheSchoolDetails(localDatabase, settings);

  @override
  Future<void> updateSchoolDetailsLocally({
    required String schoolName,
    required String schoolRegion,
    required String schoolDivision,
    required String schoolYear,
    required String schoolCode,
    String? schoolDistrict,
    String? schoolHeadName,
    String? schoolHeadPosition,
    SyncStatus syncStatus = SyncStatus.synced,
    Transaction? txn,
  }) =>
      ops.updateSchoolDetailsLocally(
        localDatabase,
        schoolName: schoolName,
        schoolRegion: schoolRegion,
        schoolDivision: schoolDivision,
        schoolYear: schoolYear,
        schoolCode: schoolCode,
        schoolDistrict: schoolDistrict,
        schoolHeadName: schoolHeadName,
        schoolHeadPosition: schoolHeadPosition,
        syncStatus: syncStatus,
        txn: txn,
      );
}
