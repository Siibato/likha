import 'package:likha/core/database/local_database.dart';
import 'package:likha/core/sync/sync_queue.dart';
import 'package:likha/data/models/setup/school_settings_model.dart';
import 'operations/setup.dart' as ops;

abstract class SetupLocalDataSource {
  LocalDatabase get localDatabase;

  Future<SchoolSettingsModel> getCachedSchoolSettings();
  Future<void> cacheSchoolSettings(SchoolSettingsModel settings);
  Future<void> updateSchoolSettingsLocally({
    required String schoolName,
    required String schoolRegion,
    required String schoolDivision,
    required String schoolYear,
    required String schoolCode,
    String? schoolDistrict,
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
  Future<SchoolSettingsModel> getCachedSchoolSettings() =>
      ops.getCachedSchoolSettings(localDatabase);

  @override
  Future<void> cacheSchoolSettings(SchoolSettingsModel settings) =>
      ops.cacheSchoolSettings(localDatabase, settings);

  @override
  Future<void> updateSchoolSettingsLocally({
    required String schoolName,
    required String schoolRegion,
    required String schoolDivision,
    required String schoolYear,
    required String schoolCode,
    String? schoolDistrict,
    SyncStatus syncStatus = SyncStatus.synced,
    Transaction? txn,
  }) =>
      ops.updateSchoolSettingsLocally(
        localDatabase,
        schoolName: schoolName,
        schoolRegion: schoolRegion,
        schoolDivision: schoolDivision,
        schoolYear: schoolYear,
        schoolCode: schoolCode,
        schoolDistrict: schoolDistrict,
        syncStatus: syncStatus,
        txn: txn,
      );
}
