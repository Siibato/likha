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
import 'package:likha/services/storage_service.dart';
import 'package:uuid/uuid.dart';

ResultFuture<MutationResult<AssignmentSubmission>> createSubmission(
  AssignmentLocalDataSource localDataSource,
  SyncQueue syncQueue,
  StorageService storageService,
  AssignmentRemoteDataSource remoteDataSource, {
  required String assignmentId,
  String? textContent,
}) async {
  try {
    final studentId = await storageService.getUserId() ?? '';
    final queueEntryId = const Uuid().v4();

    final submissionId = await localDataSource.createSubmission(
      assignmentId: assignmentId,
      studentId: studentId,
      textContent: textContent,
      queueEntryId: queueEntryId,
    );

    final cached = await localDataSource.getCachedSubmission(submissionId);
    if (cached != null) {
      fireRemoteWrite<AssignmentSubmissionModel>(
        remote: () => remoteDataSource.createSubmission(
          assignmentId: assignmentId,
          textContent: textContent,
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

      return Right(MutationResult(entity: cached, status: SyncStatus.pending));
    }

    final now = DateTime.now();
    return Right(MutationResult(
      entity: AssignmentSubmission(
        id: submissionId,
        assignmentId: assignmentId,
        studentId: studentId,
        studentName: '',
        status: 'draft',
        textContent: textContent,
        score: null,
        feedback: null,
        files: const [],
        submittedAt: null,
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
