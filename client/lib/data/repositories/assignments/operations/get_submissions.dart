import 'package:dartz/dartz.dart';
import 'package:likha/core/errors/exceptions.dart';
import 'package:likha/core/errors/failures.dart';
import 'package:likha/core/events/data_event_bus.dart';
import 'package:likha/core/utils/remote_fetch.dart';
import 'package:likha/core/utils/typedef.dart';
import 'package:likha/data/models/assignments/assignment_submission_model.dart';
import 'package:likha/domain/assignments/entities/assignment_submission.dart';
import 'package:likha/data/datasources/local/assignments/assignment_local_datasource.dart';
import 'package:likha/data/datasources/remote/assignments/assignment_remote_datasource.dart';

ResultFuture<List<SubmissionListItem>> getSubmissions(
  AssignmentLocalDataSource localDataSource,
  AssignmentRemoteDataSource remoteDataSource,
  DataEventBus dataEventBus, {
  required String assignmentId,
}) async {
  try {
    try {
      final cached = await localDataSource.getCachedSubmissions(assignmentId);

      fireRemoteFetch(
        dedupKey: 'assignments/submissions/$assignmentId/bg',
        remote: () => remoteDataSource.getSubmissions(assignmentId: assignmentId),
        onSuccess: (fresh) async {
          try {
            final current = await localDataSource.getCachedSubmissions(assignmentId);
            if (_submissionsHaveChanged(current, fresh)) {
              await localDataSource.cacheSubmissions(
                assignmentId, fresh.cast<SubmissionListItemModel>());
            }
            String? classId;
            try {
              final assignment = await localDataSource.getCachedAssignmentDetail(assignmentId);
              classId = assignment.classId;
            } catch (_) {}
            if (classId != null) {
              dataEventBus.notifyAssignmentsChanged(classId);
            }
          } catch (_) {
            await localDataSource.cacheSubmissions(
              assignmentId, fresh.cast<SubmissionListItemModel>());
          }
        },
      );

      return Right(cached);
    } on CacheException {
      final fresh = await remoteFetch(
        dedupKey: 'assignments/submissions/$assignmentId',
        remote: () => remoteDataSource.getSubmissions(assignmentId: assignmentId),
      );
      await localDataSource.cacheSubmissions(
        assignmentId, fresh.cast<SubmissionListItemModel>());

      final sorted = [...fresh]..sort((a, b) {
        if (a.submittedAt == null && b.submittedAt == null) return 0;
        if (a.submittedAt == null) return 1;
        if (b.submittedAt == null) return -1;
        return a.submittedAt!.compareTo(b.submittedAt!);
      });

      return Right(sorted);
    }
  } on ServerException catch (e) {
    return Left(ServerFailure(e.message, statusCode: e.statusCode));
  } on NetworkException catch (e) {
    return Left(NetworkFailure(e.message));
  } catch (e) {
    return Left(ServerFailure(e.toString()));
  }
}

bool _submissionsHaveChanged(List<SubmissionListItem> local, List<SubmissionListItem> remote) {
  if (local.length != remote.length) return true;
  final localById = {for (final s in local) s.id: s};
  for (final r in remote) {
    final l = localById[r.id];
    if (l == null) return true;
    if (l.status != r.status || l.score != r.score || l.submittedAt != r.submittedAt) return true;
  }
  return false;
}
