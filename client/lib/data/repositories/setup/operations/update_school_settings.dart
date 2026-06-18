import 'package:dartz/dartz.dart';
import 'package:likha/core/errors/failures.dart';
import 'package:likha/core/sync/mutation_result.dart';
import 'package:likha/core/sync/sync_queue.dart';
import 'package:likha/core/utils/typedef.dart';
import 'package:likha/data/datasources/local/setup/setup_local_datasource.dart';
import 'package:likha/data/models/setup/school_settings_model.dart';
import 'package:uuid/uuid.dart';

ResultFuture<MutationResult<SchoolSettingsModel>> updateSchoolSettings(
  SetupLocalDataSource localDataSource,
  SyncQueue syncQueue, {
  required String schoolName,
  required String schoolRegion,
  required String schoolDivision,
  required String schoolYear,
  required String schoolCode,
  String? schoolDistrict,
}) async {
  try {
    final queueEntryId = const Uuid().v4();
    final now = DateTime.now();

    final optimisticModel = SchoolSettingsModel(
      id: '1',
      schoolName: schoolName,
      schoolRegion: schoolRegion,
      schoolDivision: schoolDivision,
      schoolYear: schoolYear,
      schoolCode: schoolCode,
      schoolDistrict: schoolDistrict,
      cachedAt: now,
      syncStatus: SyncStatus.pending,
    );

    final db = await localDataSource.localDatabase.database;
    await db.transaction((txn) async {
      await localDataSource.updateSchoolSettingsLocally(
        schoolName: schoolName,
        schoolRegion: schoolRegion,
        schoolDivision: schoolDivision,
        schoolYear: schoolYear,
        schoolCode: schoolCode,
        schoolDistrict: schoolDistrict,
        syncStatus: SyncStatus.pending,
        txn: txn,
      );
      await syncQueue.enqueue(
        SyncQueueEntry(
          id: queueEntryId,
          entityType: SyncEntityType.schoolSettings,
          operation: SyncOperation.update,
          payload: optimisticModel.toPayload(),
          status: SyncStatus.pending,
          retryCount: 0,
          maxRetries: 5,
          createdAt: now,
        ),
        txn: txn,
      );
    });

    return Right(
      MutationResult(entity: optimisticModel, status: SyncStatus.pending),
    );
  } catch (e) {
    return Left(ServerFailure(e.toString()));
  }
}
