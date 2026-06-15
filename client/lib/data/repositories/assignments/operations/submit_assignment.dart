import 'package:dartz/dartz.dart';
import 'package:likha/core/database/db_schema.dart';
import 'package:likha/core/errors/exceptions.dart';
import 'package:likha/core/errors/failures.dart';
import 'package:likha/core/sync/mutation_result.dart';
import 'package:likha/core/sync/sync_queue.dart';
import 'package:likha/core/utils/remote_write.dart';
import 'package:likha/core/utils/typedef.dart';
import 'package:likha/data/datasources/local/assignments/assignment_local_datasource.dart';
import 'package:likha/data/datasources/remote/assignments/assignment_remote_datasource.dart';
import 'package:likha/data/models/assignments/assignment_submission_model.dart';
import 'package:likha/domain/assignments/entities/assignment_submission.dart';
import 'package:uuid/uuid.dart';

ResultFuture<MutationResult<AssignmentSubmission>> submitAssignment(
  AssignmentLocalDataSource localDataSource,
  SyncQueue syncQueue,
  AssignmentRemoteDataSource remoteDataSource, {
  required String submissionId,
}) async {
  try {
    final cached = await localDataSource.getCachedSubmission(submissionId);
    final assignmentId = cached?.assignmentId ?? '';
    final now = DateTime.now();
    final queueEntryId = const Uuid().v4();

    final optimisticSubmission = AssignmentSubmission(
      id: submissionId,
      assignmentId: assignmentId,
      studentId: cached?.studentId ?? '',
      studentName: cached?.studentName ?? '',
      status: 'submitted',
      files: cached?.files ?? const [],
      textContent: cached?.textContent,
      score: cached?.score,
      feedback: cached?.feedback,
      submittedAt: now,
      gradedAt: cached?.gradedAt,
      createdAt: cached?.createdAt ?? now,
      updatedAt: now,
      syncStatus: SyncStatus.pending,
      cachedAt: now,
    );

    await localDataSource.submitAssignment(
      submissionId: submissionId,
      assignmentId: assignmentId,
      queueEntryId: queueEntryId,
    );

    fireRemoteWrite<AssignmentSubmissionModel>(
      remote: () => remoteDataSource.submitAssignment(
        submissionId: submissionId,
        idempotencyKey: queueEntryId,
      ),
      onSuccess: (_) async {
        final db = await localDataSource.localDatabase.database;
        await db.update(
          DbTables.assignmentSubmissions,
          {CommonCols.syncStatus: SyncStatus.synced.dbValue},
          where: '${CommonCols.id} = ?',
          whereArgs: [submissionId],
        );
        await syncQueue.markSucceeded(queueEntryId);
      },
      onError: (error) async {
        if (error is NetworkException) {
          return;
        }
        final db = await localDataSource.localDatabase.database;
        await db.update(
          DbTables.assignmentSubmissions,
          {CommonCols.syncStatus: SyncStatus.failed.dbValue},
          where: '${CommonCols.id} = ?',
          whereArgs: [submissionId],
        );
        await syncQueue.markFailed(queueEntryId, error.toString());
      },
    );

    return Right(MutationResult(entity: optimisticSubmission, status: SyncStatus.pending));
  } catch (e) {
    return Left(ServerFailure(e.toString()));
  }
}
