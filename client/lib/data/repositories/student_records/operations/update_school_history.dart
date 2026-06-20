import 'package:dartz/dartz.dart';
import 'package:likha/core/errors/failures.dart';
import 'package:likha/core/sync/sync_queue.dart';
import 'package:likha/core/utils/typedef.dart';
import 'package:likha/data/datasources/local/student_records/student_records_local_datasource.dart';
import 'package:likha/data/models/student_records/school_history_model.dart';
import 'package:likha/domain/student_records/entities/school_history.dart';
import 'package:uuid/uuid.dart';

ResultFuture<SchoolHistory> updateSchoolHistory(
  StudentRecordsLocalDataSource localDataSource,
  SyncQueue syncQueue, {
  required String classId,
  required String studentId,
  required String historyId,
  required Map<String, dynamic> data,
}) async {
  try {
    final queueEntryId = const Uuid().v4();
    final now = DateTime.now();

    final model = SchoolHistoryModel(
      id: historyId,
      studentId: studentId,
      schoolName: data['school_name'] as String,
      schoolId: data['school_id'] as String?,
      gradeLevel: data['grade_level'] as String,
      schoolYear: data['school_year'] as String,
      section: data['section'] as String?,
      dateFrom: data['date_from'] as String?,
      dateTo: data['date_to'] as String?,
      recordType: data['record_type'] as String? ?? 'previous',
    );

    final payload = {
      ...model.toJson(),
      'class_id': classId,
      'student_id': studentId,
    };

    final db = await localDataSource.localDatabase.database;
    await db.transaction((txn) async {
      await localDataSource.updateSchoolHistory(model, txn: txn);
      await syncQueue.enqueue(
        SyncQueueEntry(
          id: queueEntryId,
          entityType: SyncEntityType.schoolHistory,
          operation: SyncOperation.update,
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
