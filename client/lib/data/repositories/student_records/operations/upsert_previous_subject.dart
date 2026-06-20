import 'package:dartz/dartz.dart';
import 'package:likha/core/errors/failures.dart';
import 'package:likha/core/sync/sync_queue.dart';
import 'package:likha/core/utils/typedef.dart';
import 'package:likha/data/datasources/local/student_records/student_records_local_datasource.dart';
import 'package:likha/data/models/student_records/previous_subject_model.dart';
import 'package:likha/domain/student_records/entities/previous_subject.dart';
import 'package:uuid/uuid.dart';

ResultFuture<PreviousSubject> upsertPreviousSubject(
  StudentRecordsLocalDataSource localDataSource,
  SyncQueue syncQueue, {
  required String classId,
  required String studentId,
  required Map<String, dynamic> data,
}) async {
  try {
    final entityId = data['id'] as String? ?? const Uuid().v4();
    final queueEntryId = const Uuid().v4();
    final now = DateTime.now();

    final model = PreviousSubjectModel(
      id: entityId,
      studentId: studentId,
      schoolHistoryId: data['school_history_id'] as String,
      subjectName: data['subject_name'] as String,
      subjectGroup: data['subject_group'] as String?,
      q1Grade: data['q1_grade'] as int?,
      q2Grade: data['q2_grade'] as int?,
      q3Grade: data['q3_grade'] as int?,
      q4Grade: data['q4_grade'] as int?,
      finalGrade: data['final_grade'] as int?,
      descriptor: data['descriptor'] as String?,
    );

    final payload = {
      ...model.toJson(),
      'class_id': classId,
      'student_id': studentId,
    };

    final db = await localDataSource.localDatabase.database;
    await db.transaction((txn) async {
      await localDataSource.insertPreviousSubject(model, txn: txn);
      await syncQueue.enqueue(
        SyncQueueEntry(
          id: queueEntryId,
          entityType: SyncEntityType.previousSchoolSubjects,
          operation: SyncOperation.create,
          payload: payload,
          status: SyncStatus.pending,
          retryCount: 0,
          maxRetries: 5,
          createdAt: now,
        ),
        txn: txn,
      );
    });

    return Right(model);
  } catch (e) {
    return Left(ServerFailure(e.toString()));
  }
}
