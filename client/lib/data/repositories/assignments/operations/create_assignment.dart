import 'package:dartz/dartz.dart';
import 'package:likha/core/errors/failures.dart';
import 'package:likha/core/sync/mutation_result.dart';
import 'package:likha/core/sync/sync_queue.dart';
import 'package:likha/core/utils/typedef.dart';
import 'package:likha/data/datasources/local/assignments/assignment_local_datasource.dart';
import 'package:likha/data/models/assignments/assignment_model.dart';
import 'package:likha/domain/assignments/entities/assignment.dart';
import 'package:uuid/uuid.dart';

ResultFuture<MutationResult<Assignment>> createAssignment(
  AssignmentLocalDataSource localDataSource,
  SyncQueue syncQueue,
  {
  required String classId,
  required String title,
  required String instructions,
  required int totalPoints,
  required bool allowsTextSubmission,
  required bool allowsFileSubmission,
  String? allowedFileTypes,
  int? maxFileSizeMb,
  required String dueAt,
  bool isPublished = true,
  int? termNumber,
  String? component,
  bool? noSubmissionRequired,
}) async {
  try {
    final assignmentId = const Uuid().v4();
    final queueEntryId = const Uuid().v4();
    final now = DateTime.now();

    final optimisticModel = AssignmentModel(
      id: assignmentId,
      classId: classId,
      title: title,
      instructions: instructions,
      totalPoints: totalPoints,
      allowsTextSubmission: allowsTextSubmission,
      allowsFileSubmission: allowsFileSubmission,
      allowedFileTypes: allowedFileTypes,
      maxFileSizeMb: maxFileSizeMb,
      dueAt: DateTime.parse(dueAt),
      isPublished: isPublished,
      orderIndex: 0,
      submissionCount: 0,
      gradedCount: 0,
      termNumber: termNumber,
      component: component,
      createdAt: now,
      updatedAt: now,
      syncStatus: SyncStatus.pending,
    );

    final data = {
      ...optimisticModel.toPayload(),
      if (noSubmissionRequired != null) 'no_submission_required': noSubmissionRequired,
    };

    final db = await localDataSource.localDatabase.database;
    await db.transaction((txn) async {
      await localDataSource.insertAssignment(optimisticModel, txn: txn);
      await syncQueue.enqueue(
        SyncQueueEntry(
          id: queueEntryId,
          entityType: SyncEntityType.assignment,
          operation: SyncOperation.create,
          payload: data,
          status: SyncStatus.pending,
          retryCount: 0,
          maxRetries: 5,
          createdAt: now,
        ),
        txn: txn,
      );
    });

    return Right(MutationResult(entity: optimisticModel, status: SyncStatus.pending));
  } catch (e) {
    return Left(ServerFailure(e.toString()));
  }
}
