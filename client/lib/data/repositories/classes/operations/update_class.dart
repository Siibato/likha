import 'package:dartz/dartz.dart';
import 'package:likha/core/errors/failures.dart';
import 'package:likha/core/sync/mutation_result.dart';
import 'package:likha/core/sync/sync_queue.dart';
import 'package:likha/core/utils/typedef.dart';
import 'package:likha/data/datasources/local/classes/class_local_datasource.dart';
import 'package:likha/data/models/classes/class_model.dart';
import 'package:likha/domain/classes/entities/class_entity.dart';
import 'package:uuid/uuid.dart';

ResultFuture<MutationResult<ClassEntity>> updateClass(
  ClassLocalDataSource localDataSource,
  SyncQueue syncQueue,
  {
  required String classId,
  String? title,
  String? description,
  String? teacherId,
  bool? isAdvisory,
}) async {
  try {
    final queueEntryId = const Uuid().v4();
    final now = DateTime.now();

    final current = await localDataSource
        .getCachedClasses()
        .then((classes) => classes.firstWhere(
              (c) => c.id == classId,
              orElse: () => throw Exception('Class not found'),
            ));

    final optimisticModel = ClassModel(
      id: current.id,
      title: title ?? current.title,
      description: description ?? current.description,
      teacherId: teacherId ?? current.teacherId,
      teacherUsername: current.teacherUsername,
      teacherFullName: current.teacherFullName,
      isArchived: current.isArchived,
      isAdvisory: isAdvisory ?? current.isAdvisory,
      studentCount: current.studentCount,
      gradingPeriodType: current.gradingPeriodType,
      createdAt: current.createdAt,
      updatedAt: now,
      syncStatus: SyncStatus.pending,
    );

    final db = await localDataSource.localDatabase.database;
    await db.transaction((txn) async {
      await localDataSource.updateClassLocally(
        classId: classId,
        title: title,
        description: description,
        isAdvisory: isAdvisory,
        txn: txn,
      );
      await syncQueue.enqueue(
        SyncQueueEntry(
          id: queueEntryId,
          entityType: SyncEntityType.classEntity,
          operation: SyncOperation.update,
          payload: {
            'id': classId,
            if (title != null) 'title': title,
            if (description != null) 'description': description,
            if (teacherId != null) 'teacher_id': teacherId,
            if (isAdvisory != null) 'is_advisory': isAdvisory,
          },
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
