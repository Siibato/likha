import 'package:dartz/dartz.dart';
import 'package:likha/core/errors/failures.dart';
import 'package:likha/core/sync/sync_queue.dart';
import 'package:likha/core/utils/typedef.dart';
import 'package:likha/data/datasources/local/student_records/student_records_local_datasource.dart';
import 'package:uuid/uuid.dart';

ResultFuture<void> deleteSchoolHistory(
  StudentRecordsLocalDataSource localDataSource,
  SyncQueue syncQueue, {
  required String classId,
  required String studentId,
  required String historyId,
}) async {
  try {
    final queueEntryId = const Uuid().v4();
    final now = DateTime.now();

    final payload = {
      'id': historyId,
      'class_id': classId,
      'student_id': studentId,
    };

    final db = await localDataSource.localDatabase.database;
    await db.transaction((txn) async {
      await localDataSource.deleteSchoolHistory(historyId, txn: txn);
      await syncQueue.enqueue(
        SyncQueueEntry(
          id: queueEntryId,
          entityType: SyncEntityType.schoolHistory,
          operation: SyncOperation.delete,
          payload: payload,
          status: SyncStatus.pending,
          retryCount: 0,
          maxRetries: 5,
          createdAt: now,
        ),
        txn: txn,
      );
    });

    return const Right(null);
  } catch (e) {
    return Left(ServerFailure(e.toString()));
  }
}
