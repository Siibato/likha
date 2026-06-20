import 'package:dartz/dartz.dart';
import 'package:likha/core/errors/failures.dart';
import 'package:likha/core/sync/mutation_result.dart';
import 'package:likha/core/sync/sync_queue.dart';
import 'package:likha/core/utils/typedef.dart';
import 'package:likha/data/datasources/local/assignments/assignment_local_datasource.dart';
import 'package:uuid/uuid.dart';

ResultFuture<MutationResult<void>> reorderAllAssignments(
  AssignmentLocalDataSource localDataSource,
  SyncQueue syncQueue,
  {
  required String classId,
  required List<String> assignmentIds,
}) async {
  try {
    final queueEntryId = const Uuid().v4();
    final db = await localDataSource.localDatabase.database;
    await db.transaction((txn) async {
      for (int i = 0; i < assignmentIds.length; i++) {
        await localDataSource.updateAssignmentOrder(
          assignmentId: assignmentIds[i],
          orderIndex: i,
          txn: txn,
        );
      }
      await syncQueue.enqueue(
        SyncQueueEntry(
          id: queueEntryId,
          entityType: SyncEntityType.assignment,
          operation: SyncOperation.update,
          payload: {
            'class_id': classId,
            'assignment_ids': assignmentIds,
          },
          status: SyncStatus.pending,
          retryCount: 0,
          maxRetries: 5,
          createdAt: DateTime.now(),
        ),
        txn: txn,
      );
    });

    return const Right(MutationResult(entity: null, status: SyncStatus.pending));
  } catch (e) {
    return Left(ServerFailure(e.toString()));
  }
}
