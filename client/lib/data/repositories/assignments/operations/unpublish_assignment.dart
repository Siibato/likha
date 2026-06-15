import 'package:dartz/dartz.dart';
import 'package:likha/core/errors/failures.dart';
import 'package:likha/core/sync/mutation_result.dart';
import 'package:likha/core/sync/sync_queue.dart';
import 'package:likha/core/utils/typedef.dart';
import 'package:likha/domain/assignments/entities/assignment.dart';
import 'package:likha/data/datasources/local/assignments/assignment_local_datasource.dart';

ResultFuture<MutationResult<Assignment>> unpublishAssignment(
  AssignmentLocalDataSource localDataSource,
  SyncQueue syncQueue, {
  required String assignmentId,
}) async {
  try {
    await localDataSource.markAssignmentUnpublished(assignmentId: assignmentId);
    final cached = await localDataSource.getCachedAssignmentDetail(assignmentId);

    return Right(MutationResult(entity: cached, status: SyncStatus.pending));
  } catch (e) {
    return Left(ServerFailure(e.toString()));
  }
}
