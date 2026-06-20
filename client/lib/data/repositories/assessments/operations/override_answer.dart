import 'package:dartz/dartz.dart';
import 'package:likha/core/database/db_schema.dart';
import 'package:likha/core/errors/failures.dart';
import 'package:likha/core/events/data_event_bus.dart';
import 'package:likha/core/sync/mutation_result.dart';
import 'package:likha/core/sync/sync_queue.dart';
import 'package:likha/core/utils/typedef.dart';
import 'package:likha/data/datasources/local/assessments/assessment_local_datasource.dart';
import 'package:likha/domain/assessments/entities/submission.dart';
import 'package:uuid/uuid.dart';

ResultFuture<MutationResult<SubmissionAnswer>> overrideAnswer(
  AssessmentLocalDataSource localDataSource,
  SyncQueue syncQueue,
  DataEventBus dataEventBus, {
  required String answerId,
  required bool isCorrect,
  double? points,
}) async {
  try {
    final now = DateTime.now();
    final queueEntryId = const Uuid().v4();

    final payload = {
      'answer_id': answerId,
      'is_correct': isCorrect,
      if (points != null) 'points': points,
    };

    final db = await localDataSource.localDatabase.database;
    await db.transaction((txn) async {
      await localDataSource.overrideAnswer(
        answerId: answerId,
        isCorrect: isCorrect,
        points: points,
        txn: txn,
      );
      await syncQueue.enqueue(
        SyncQueueEntry(
          id: queueEntryId,
          entityType: SyncEntityType.assessment,
          operation: SyncOperation.overrideAnswer,
          payload: payload,
          status: SyncStatus.pending,
          retryCount: 0,
          maxRetries: 5,
          createdAt: now,
        ),
        txn: txn,
      );
    });

    // Query assessmentId for statistics notification
    final answerRows = await db.query(
      DbTables.submissionAnswers,
      columns: [SubmissionAnswersCols.submissionId],
      where: '${CommonCols.id} = ?',
      whereArgs: [answerId],
      limit: 1,
    );
    if (answerRows.isNotEmpty) {
      final submissionId = answerRows.first[SubmissionAnswersCols.submissionId] as String;
      final subRows = await db.query(
        DbTables.assessmentSubmissions,
        columns: [AssessmentSubmissionsCols.assessmentId],
        where: '${CommonCols.id} = ?',
        whereArgs: [submissionId],
        limit: 1,
      );
      if (subRows.isNotEmpty) {
        final assessmentId = subRows.first[AssessmentSubmissionsCols.assessmentId] as String;
        dataEventBus.notifyStatisticsChanged(assessmentId);
      }
    }

    final optimisticModel = SubmissionAnswer(
      id: answerId,
      questionId: '',
      questionText: '',
      questionType: '',
      points: 0,
      isOverrideCorrect: isCorrect,
      pointsAwarded: points ?? (isCorrect ? 0 : 0),
    );

    return Right(MutationResult(entity: optimisticModel, status: SyncStatus.pending));
  } catch (e) {
    return Left(ServerFailure(e.toString()));
  }
}
