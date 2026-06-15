import 'package:dartz/dartz.dart';
import 'package:likha/core/errors/failures.dart';
import 'package:likha/core/sync/mutation_result.dart';
import 'package:likha/core/sync/sync_queue.dart';
import 'package:likha/core/utils/typedef.dart';
import 'package:likha/domain/assignments/entities/assignment_submission.dart';
import 'package:likha/data/datasources/local/assignments/assignment_local_datasource.dart';

ResultFuture<MutationResult<AssignmentSubmission>> submitAssignment(
  AssignmentLocalDataSource localDataSource,
  SyncQueue syncQueue, {
  required String submissionId,
}) async {
  try {
    final cached = await localDataSource.getCachedSubmission(submissionId);
    final assignmentId = cached?.assignmentId ?? '';
    final now = DateTime.now();

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

    final db = await localDataSource.localDatabase.database;
    await db.transaction((txn) async {
      await localDataSource.submitAssignment(
        submissionId: submissionId,
        assignmentId: assignmentId,
        txn: txn,
      );
    });

    return Right(MutationResult(entity: optimisticSubmission, status: SyncStatus.pending));
  } catch (e) {
    return Left(ServerFailure(e.toString()));
  }
}
