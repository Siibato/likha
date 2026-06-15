import 'package:dartz/dartz.dart';
import 'package:uuid/uuid.dart';
import 'package:likha/core/errors/failures.dart';
import 'package:likha/core/sync/mutation_result.dart';
import 'package:likha/core/sync/sync_queue.dart';
import 'package:likha/core/utils/typedef.dart';
import 'package:likha/data/datasources/local/grading/grading_local_datasource.dart';

ResultFuture<MutationResult<void>> updateTransmutedGrade(
  GradingLocalDataSource localDataSource,
  SyncQueue syncQueue, {
  required String classId,
  required String studentId,
  required int gradingPeriodNumber,
  required int transmutedGrade,
}) async {
  try {
    final queueEntryId = const Uuid().v4();
    final now = DateTime.now();

    final db = await localDataSource.localDatabase.database;
    await db.transaction((txn) async {
      await localDataSource.updateTransmutedGrade(
        classId,
        studentId,
        gradingPeriodNumber,
        transmutedGrade,
        txn: txn,
      );
      await syncQueue.enqueue(
        SyncQueueEntry(
          id: queueEntryId,
          entityType: SyncEntityType.gradeScore,
          operation: SyncOperation.update,
          payload: {
            'class_id': classId,
            'student_id': studentId,
            'grading_period_number': gradingPeriodNumber,
            'transmuted_grade': transmutedGrade,
          },
          status: SyncStatus.pending,
          retryCount: 0,
          maxRetries: 5,
          createdAt: now,
        ),
        txn: txn,
      );
    });
    return const Right(MutationResult(entity: null, status: SyncStatus.pending));
  } catch (e) {
    return Left(ServerFailure(e.toString()));
  }
}
