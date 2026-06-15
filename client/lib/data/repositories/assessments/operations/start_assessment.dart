import 'package:dartz/dartz.dart';
import 'package:likha/core/database/db_schema.dart';
import 'package:likha/core/errors/exceptions.dart';
import 'package:likha/core/errors/failures.dart';
import 'package:likha/core/sync/mutation_result.dart';
import 'package:likha/core/sync/sync_queue.dart';
import 'package:likha/core/utils/remote_write.dart';
import 'package:likha/core/utils/typedef.dart';
import 'package:likha/data/datasources/local/assessments/assessment_local_datasource.dart';
import 'package:likha/data/datasources/remote/assessments/assessment_remote_datasource.dart';
import 'package:likha/data/models/assessments/submission_model.dart';
import 'package:likha/domain/assessments/entities/submission.dart';
import 'package:uuid/uuid.dart';

ResultFuture<MutationResult<StartSubmissionResult>> startAssessment(
  AssessmentLocalDataSource localDataSource,
  SyncQueue syncQueue,
  AssessmentRemoteDataSource remoteDataSource, {
  required String assessmentId,
  required String studentId,
  required String studentName,
  required String studentUsername,
}) async {
  try {
    final existingSubmission = await localDataSource.getCachedStudentSubmission(
      assessmentId,
      studentId,
    );

    if (existingSubmission != null && existingSubmission.isSubmitted) {
      return const Left(ServerFailure('Assessment already submitted'));
    }

    final (_, questions) = await localDataSource.getCachedAssessmentDetail(assessmentId);
    final questionMaps = questions.map((q) => {
      'id': q.id,
      'question_type': q.questionType,
      'question_text': q.questionText,
      'points': q.points,
      'order_index': q.orderIndex,
      'is_multi_select': q.isMultiSelect,
      if (q.choices != null)
        'choices': q.choices!
            .map((c) => {
                  'id': c.id,
                  'choice_text': c.choiceText,
                  'order_index': c.orderIndex,
                })
            .toList(),
      if (q.enumerationItems != null)
        'enumeration_count': q.enumerationItems!.length,
    }).toList();

    if (existingSubmission != null && !existingSubmission.isSubmitted) {
      final result = StartSubmissionResult(
        submissionId: existingSubmission.id,
        startedAt: existingSubmission.startedAt,
        questions: questionMaps,
      );
      return Right(MutationResult(entity: result, status: existingSubmission.syncStatus));
    }

    final now = DateTime.now();
    final queueEntryId = const Uuid().v4();
    late String localId;

    final db = await localDataSource.localDatabase.database;
    await db.transaction((txn) async {
      localId = await localDataSource.startAssessment(
        assessmentId: assessmentId,
        studentId: studentId,
        studentName: studentName,
        studentUsername: studentUsername,
        txn: txn,
      );
      await syncQueue.enqueue(
        SyncQueueEntry(
          id: queueEntryId,
          entityType: SyncEntityType.assessmentSubmission,
          operation: SyncOperation.create,
          payload: {
            'id': localId,
            'assessment_id': assessmentId,
            'user_id': studentId,
          },
          status: SyncStatus.pending,
          retryCount: 0,
          maxRetries: 5,
          createdAt: now,
        ),
        txn: txn,
      );
    });

    final result = StartSubmissionResult(
      submissionId: localId,
      startedAt: now,
      questions: questionMaps,
    );

    fireRemoteWrite<StartSubmissionResultModel>(
      remote: () => remoteDataSource.startAssessment(
        assessmentId: assessmentId,
        idempotencyKey: queueEntryId,
      ),
      onSuccess: (serverResult) async {
        final db = await localDataSource.localDatabase.database;
        if (serverResult.submissionId != localId) {
          await db.update(
            DbTables.assessmentSubmissions,
            {CommonCols.id: serverResult.submissionId},
            where: '${CommonCols.id} = ?',
            whereArgs: [localId],
          );
        }
        await db.update(
          DbTables.assessmentSubmissions,
          {CommonCols.syncStatus: SyncStatus.synced.dbValue},
          where: '${CommonCols.id} = ?',
          whereArgs: [serverResult.submissionId],
        );
        await syncQueue.markSucceeded(queueEntryId);
      },
      onError: (error) async {
        if (error is NetworkException) {
          return;
        }
        final db = await localDataSource.localDatabase.database;
        await db.update(
          DbTables.assessmentSubmissions,
          {CommonCols.syncStatus: SyncStatus.failed.dbValue},
          where: '${CommonCols.id} = ?',
          whereArgs: [localId],
        );
        await syncQueue.markFailed(queueEntryId, error.toString());
      },
    );

    return Right(MutationResult(entity: result, status: SyncStatus.pending));
  } catch (e) {
    return Left(ServerFailure(e.toString()));
  }
}
