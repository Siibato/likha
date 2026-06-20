import 'package:dartz/dartz.dart';
import 'package:likha/core/errors/exceptions.dart';
import 'package:likha/core/errors/failures.dart';
import 'package:likha/core/sync/mutation_result.dart';
import 'package:likha/core/sync/sync_queue.dart';
import 'package:likha/core/utils/typedef.dart';
import 'package:likha/data/datasources/local/setup/setup_local_datasource.dart';
import 'package:likha/data/models/setup/school_details_model.dart';
import 'package:uuid/uuid.dart';

ResultFuture<MutationResult<SchoolDetailsModel>> updateSchoolCode(
  SetupLocalDataSource localDataSource,
  SyncQueue syncQueue, {
  required String schoolCode,
}) async {
  try {
    final queueEntryId = const Uuid().v4();
    final now = DateTime.now();

    // Read current settings to preserve other fields
    SchoolDetailsModel current;
    try {
      current = await localDataSource.getCachedSchoolDetails();
    } on CacheException {
      current = const SchoolDetailsModel(
        id: '1',
        schoolName: '',
        schoolRegion: '',
        schoolDivision: '',
        schoolYear: '',
        schoolCode: '',
      );
    }

    final optimisticModel = SchoolDetailsModel(
      id: '1',
      schoolName: current.schoolName,
      schoolRegion: current.schoolRegion,
      schoolDivision: current.schoolDivision,
      schoolYear: current.schoolYear,
      schoolCode: schoolCode,
      cachedAt: now,
      syncStatus: SyncStatus.pending,
    );

    final db = await localDataSource.localDatabase.database;
    await db.transaction((txn) async {
      await localDataSource.updateSchoolDetailsLocally(
        schoolName: optimisticModel.schoolName,
        schoolRegion: optimisticModel.schoolRegion,
        schoolDivision: optimisticModel.schoolDivision,
        schoolYear: optimisticModel.schoolYear,
        schoolCode: schoolCode,
        syncStatus: SyncStatus.pending,
        txn: txn,
      );
      await syncQueue.enqueue(
        SyncQueueEntry(
          id: queueEntryId,
          entityType: SyncEntityType.schoolDetails,
          operation: SyncOperation.update,
          payload: {
            ...optimisticModel.toPayload(),
            '_update_code_only': true,
          },
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
