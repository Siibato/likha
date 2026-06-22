import 'package:dartz/dartz.dart';
import 'package:likha/core/errors/failures.dart';
import 'package:likha/core/sync/sync_queue.dart';
import 'package:likha/core/utils/typedef.dart';
import 'package:likha/data/datasources/local/student_records/student_records_local_datasource.dart';
import 'package:likha/data/models/student_records/attendance_record_model.dart';
import 'package:likha/domain/student_records/entities/attendance_record.dart';
import 'package:uuid/uuid.dart';

ResultFuture<AttendanceRecord> upsertAttendance(
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

    final model = AttendanceRecordModel(
      id: entityId,
      studentId: studentId,
      classId: classId,
      schoolYear: data['school_year'] as String,
      month: data['month'] as String,
      schoolDays: data['school_days'] as int? ?? 0,
      daysPresent: data['days_present'] as int? ?? 0,
    );

    final payload = {
      ...model.toJson(),
      'class_id': classId,
      'student_id': studentId,
    };

    final db = await localDataSource.localDatabase.database;
    await db.transaction((txn) async {
      await localDataSource.insertAttendance(model, txn: txn);
      await syncQueue.enqueue(
        SyncQueueEntry(
          id: queueEntryId,
          entityType: SyncEntityType.attendanceRecords,
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
