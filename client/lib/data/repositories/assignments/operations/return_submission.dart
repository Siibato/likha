import 'package:dartz/dartz.dart';
import 'package:likha/core/errors/failures.dart';
import 'package:likha/core/sync/mutation_result.dart';
import 'package:likha/core/sync/sync_queue.dart';
import 'package:likha/core/utils/typedef.dart';
import 'package:likha/domain/assignments/entities/assignment_submission.dart';
import 'package:likha/data/datasources/local/assignments/assignment_local_datasource.dart';

ResultFuture<MutationResult<AssignmentSubmission>> returnSubmission(
  AssignmentLocalDataSource localDataSource,
  SyncQueue syncQueue, {
  required String submissionId,
}) async {
  try {
    await localDataSource.returnSubmission(submissionId: submissionId);

    final cached = await localDataSource.getCachedSubmission(submissionId);
    if (cached != null) {
      return Right(MutationResult(entity: cached, status: SyncStatus.pending));
    }

    final now = DateTime.now();
    return Right(MutationResult(
      entity: AssignmentSubmission(
        id: submissionId,
        assignmentId: '',
        studentId: '',
        studentName: '',
        status: 'returned',
        files: const [],
        textContent: null,
        score: null,
        feedback: null,
        submittedAt: now,
        gradedAt: null,
        createdAt: now,
        updatedAt: now,
        syncStatus: SyncStatus.pending,
        cachedAt: now,
      ),
      status: SyncStatus.pending,
    ));
  } catch (e) {
    return Left(ServerFailure(e.toString()));
  }
}
