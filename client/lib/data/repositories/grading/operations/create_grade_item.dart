import 'package:dartz/dartz.dart';
import 'package:uuid/uuid.dart';
import 'package:likha/core/errors/failures.dart';
import 'package:likha/core/events/data_event_bus.dart';
import 'package:likha/core/sync/mutation_result.dart';
import 'package:likha/core/sync/sync_queue.dart';
import 'package:likha/core/utils/typedef.dart';
import 'package:likha/data/datasources/local/grading/grading_local_datasource.dart';
import 'package:likha/data/models/grading/grade_item_model.dart';
import 'package:likha/data/models/grading/grade_score_model.dart';
import 'package:likha/domain/grading/entities/grade_item.dart';

import '_helpers.dart' as helpers;

ResultFuture<MutationResult<GradeItem>> createGradeItem(
  GradingLocalDataSource localDataSource,
  SyncQueue syncQueue,
  DataEventBus dataEventBus, {
  required String classId,
  required Map<String, dynamic> data,
}) async {
  try {
    final now = DateTime.now();
    final id = const Uuid().v4();
    final queueEntryId = const Uuid().v4();

    final model = GradeItemModel(
      id: id,
      classId: classId,
      title: data['title'] as String,
      component: data['component'] as String,
      termNumber: (data['term_number'] as num?)?.toInt() ?? 1,
      totalPoints: (data['total_points'] as num).toDouble(),
      sourceType: (data['source_type'] as String?) ?? 'manual',
      sourceId: data['source_id'] as String?,
      orderIndex: (data['order_index'] as num?)?.toInt() ?? 0,
      createdAt: now,
      updatedAt: now,
    );

    final db = await localDataSource.localDatabase.database;
    await db.transaction((txn) async {
      await localDataSource.saveItem(model, txn: txn);
      await syncQueue.enqueue(
        SyncQueueEntry(
          id: queueEntryId,
          entityType: SyncEntityType.gradeItem,
          operation: SyncOperation.create,
          payload: {
            'id': id,
            'class_id': classId,
            'term_number': model.termNumber,
            ...data,
          },
          status: SyncStatus.pending,
          retryCount: 0,
          maxRetries: 5,
          createdAt: now,
        ),
        txn: txn,
      );

      final students = await localDataSource.getEnrolledStudents(classId, txn: txn);
      final scores = students.map((student) {
        final studentId = student['id'] as String;
        return GradeScoreModel(
          id: const Uuid().v4(),
          gradeItemId: id,
          studentId: studentId,
          score: 0.0,
          isAutoPopulated: true,
          overrideScore: null,
          createdAt: now.toIso8601String(),
          updatedAt: now.toIso8601String(),
        );
      }).toList();
      await localDataSource.saveScores(scores, txn: txn);
    });

    dataEventBus.notifyGradesChanged(classId);

    return Right(MutationResult(entity: helpers.itemToEntity(model), status: SyncStatus.pending));
  } catch (e) {
    return Left(ServerFailure(e.toString()));
  }
}
