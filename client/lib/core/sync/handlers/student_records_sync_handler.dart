import 'package:likha/core/database/db_schema.dart';
import 'package:likha/core/database/local_database.dart';
import 'package:likha/core/errors/exceptions.dart';
import 'package:likha/core/logging/sync_logger.dart';
import 'package:likha/core/sync/sync_queue.dart';
import 'package:likha/core/sync/sync_result.dart';
import 'package:likha/data/datasources/remote/student_records/student_records_remote_datasource.dart';

class StudentRecordsSyncHandler {
  final StudentRecordsRemoteDataSource _remote;
  final LocalDatabase _localDatabase;
  // ignore: unused_field
  final SyncLogger _log;

  StudentRecordsSyncHandler(
    this._remote,
    this._localDatabase,
    this._log,
  );

  Future<SyncResult> handle(SyncQueueEntry entry) async {
    try {
      switch (entry.entityType) {
        case SyncEntityType.learnerDetails:
          return await _handleLearnerDetails(entry);
        case SyncEntityType.attendanceRecords:
          return await _handleAttendanceRecords(entry);
        case SyncEntityType.coreValuesRecords:
          return await _handleCoreValuesRecords(entry);
        case SyncEntityType.schoolHistory:
          return await _handleSchoolHistory(entry);
        case SyncEntityType.previousSchoolSubjects:
          return await _handlePreviousSchoolSubjects(entry);
        case SyncEntityType.previousSchoolAttendance:
          return await _handlePreviousSchoolAttendance(entry);
        default:
          return SyncResult.permanentFailure(
            'Unsupported student_records entity type: ${entry.entityType}',
          );
      }
    } on NetworkException catch (e) {
      return SyncResult.retry(e.message);
    } on ServerException catch (e) {
      return SyncResult.permanentFailure(e.message);
    } catch (e) {
      return SyncResult.permanentFailure(e.toString());
    }
  }

  Future<SyncResult> _handleLearnerDetails(SyncQueueEntry entry) async {
    final payload = entry.payload;
    final classId = payload['class_id'] as String;
    final studentId = payload['student_id'] as String;

    switch (entry.operation) {
      case SyncOperation.create:
      case SyncOperation.update:
        await _remote.upsertLearnerDetails(
          classId: classId,
          studentId: studentId,
          data: payload,
        );
        await _markSynced(DbTables.learnerDetails, payload['id'] as String);
        return const SyncResult.success();
      default:
        return SyncResult.permanentFailure(
          'Unsupported operation for learnerDetails: ${entry.operation}',
        );
    }
  }

  Future<SyncResult> _handleAttendanceRecords(SyncQueueEntry entry) async {
    final payload = entry.payload;
    final classId = payload['class_id'] as String;
    final studentId = payload['student_id'] as String;

    switch (entry.operation) {
      case SyncOperation.create:
      case SyncOperation.update:
        await _remote.upsertAttendance(
          classId: classId,
          studentId: studentId,
          data: payload,
        );
        await _markSynced(DbTables.attendanceRecords, payload['id'] as String);
        return const SyncResult.success();
      default:
        return SyncResult.permanentFailure(
          'Unsupported operation for attendanceRecords: ${entry.operation}',
        );
    }
  }

  Future<SyncResult> _handleCoreValuesRecords(SyncQueueEntry entry) async {
    final payload = entry.payload;
    final classId = payload['class_id'] as String;
    final studentId = payload['student_id'] as String;

    switch (entry.operation) {
      case SyncOperation.create:
      case SyncOperation.update:
        await _remote.upsertCoreValues(
          classId: classId,
          studentId: studentId,
          data: payload,
        );
        await _markSynced(DbTables.coreValuesRecords, payload['id'] as String);
        return const SyncResult.success();
      default:
        return SyncResult.permanentFailure(
          'Unsupported operation for coreValuesRecords: ${entry.operation}',
        );
    }
  }

  Future<SyncResult> _handleSchoolHistory(SyncQueueEntry entry) async {
    final payload = entry.payload;
    final classId = payload['class_id'] as String;
    final studentId = payload['student_id'] as String;

    switch (entry.operation) {
      case SyncOperation.create:
        await _remote.createSchoolHistory(
          classId: classId,
          studentId: studentId,
          data: payload,
        );
        await _markSynced(DbTables.studentSchoolHistory, payload['id'] as String);
        return const SyncResult.success();
      case SyncOperation.update:
        await _remote.updateSchoolHistory(
          classId: classId,
          studentId: studentId,
          historyId: payload['id'] as String,
          data: payload,
        );
        await _markSynced(DbTables.studentSchoolHistory, payload['id'] as String);
        return const SyncResult.success();
      case SyncOperation.delete:
        await _remote.deleteSchoolHistory(
          classId: classId,
          studentId: studentId,
          historyId: payload['id'] as String,
        );
        return const SyncResult.success();
      default:
        return SyncResult.permanentFailure(
          'Unsupported operation for schoolHistory: ${entry.operation}',
        );
    }
  }

  Future<SyncResult> _handlePreviousSchoolSubjects(SyncQueueEntry entry) async {
    final payload = entry.payload;
    final classId = payload['class_id'] as String;
    final studentId = payload['student_id'] as String;

    switch (entry.operation) {
      case SyncOperation.create:
      case SyncOperation.update:
        await _remote.upsertPreviousSubject(
          classId: classId,
          studentId: studentId,
          data: payload,
        );
        await _markSynced(DbTables.previousSchoolSubjects, payload['id'] as String);
        return const SyncResult.success();
      default:
        return SyncResult.permanentFailure(
          'Unsupported operation for previousSchoolSubjects: ${entry.operation}',
        );
    }
  }

  Future<SyncResult> _handlePreviousSchoolAttendance(SyncQueueEntry entry) async {
    final payload = entry.payload;
    final classId = payload['class_id'] as String;
    final studentId = payload['student_id'] as String;

    switch (entry.operation) {
      case SyncOperation.create:
      case SyncOperation.update:
        await _remote.upsertPreviousAttendance(
          classId: classId,
          studentId: studentId,
          data: payload,
        );
        await _markSynced(DbTables.previousSchoolAttendance, payload['id'] as String);
        return const SyncResult.success();
      default:
        return SyncResult.permanentFailure(
          'Unsupported operation for previousSchoolAttendance: ${entry.operation}',
        );
    }
  }

  Future<void> _markSynced(String table, String id) async {
    final db = await _localDatabase.database;
    await db.update(
      table,
      {CommonCols.syncStatus: SyncStatus.synced.dbValue},
      where: '${CommonCols.id} = ?',
      whereArgs: [id],
    );
  }
}
