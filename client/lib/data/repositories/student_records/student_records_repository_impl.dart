import 'package:likha/core/events/data_event_bus.dart';
import 'package:likha/core/sync/sync_queue.dart';
import 'package:likha/core/utils/typedef.dart';
import 'package:likha/data/datasources/local/grading/grading_local_datasource.dart';
import 'package:likha/data/datasources/local/student_records/student_records_local_datasource.dart';
import 'package:likha/data/datasources/remote/student_records/student_records_remote_datasource.dart';
import 'package:likha/domain/student_records/entities/learner_details.dart';
import 'package:likha/domain/student_records/entities/attendance_record.dart';
import 'package:likha/domain/student_records/entities/core_values_record.dart';
import 'package:likha/domain/student_records/entities/school_history.dart';
import 'package:likha/domain/student_records/entities/previous_subject.dart';
import 'package:likha/domain/student_records/entities/previous_attendance.dart';
import 'package:likha/domain/student_records/entities/sf10_response.dart';
import 'package:likha/domain/student_records/repositories/student_records_repository.dart';
import 'operations/student_records_ops.dart' as ops;

class StudentRecordsRepositoryImpl implements StudentRecordsRepository {
  final StudentRecordsRemoteDataSource _remoteDataSource;
  final StudentRecordsLocalDataSource _localDataSource;
  final GradingLocalDataSource _gradingLocalDataSource;
  final SyncQueue _syncQueue;
  final DataEventBus _dataEventBus;

  StudentRecordsRepositoryImpl(
    this._remoteDataSource,
    this._localDataSource,
    this._gradingLocalDataSource,
    this._syncQueue,
    this._dataEventBus,
  );

  @override
  ResultFuture<LearnerDetails?> getLearnerDetails({required String classId, required String studentId}) =>
      ops.getLearnerDetails(_localDataSource, _remoteDataSource, _dataEventBus, classId: classId, studentId: studentId);

  @override
  ResultFuture<LearnerDetails> upsertLearnerDetails({required String classId, required String studentId, required Map<String, dynamic> data}) =>
      ops.upsertLearnerDetails(_localDataSource, _syncQueue, classId: classId, studentId: studentId, data: data);

  @override
  ResultFuture<List<AttendanceRecord>> getAttendance({required String classId, required String studentId, String? schoolYear}) =>
      ops.getAttendance(_localDataSource, _remoteDataSource, _dataEventBus, classId: classId, studentId: studentId, schoolYear: schoolYear);

  @override
  ResultFuture<AttendanceRecord> upsertAttendance({required String classId, required String studentId, required Map<String, dynamic> data}) =>
      ops.upsertAttendance(_localDataSource, _syncQueue, classId: classId, studentId: studentId, data: data);

  @override
  ResultFuture<List<CoreValuesRecord>> getCoreValues({required String classId, required String studentId, String? schoolYear}) =>
      ops.getCoreValues(_localDataSource, _remoteDataSource, _dataEventBus, classId: classId, studentId: studentId, schoolYear: schoolYear);

  @override
  ResultFuture<CoreValuesRecord> upsertCoreValues({required String classId, required String studentId, required Map<String, dynamic> data}) =>
      ops.upsertCoreValues(_localDataSource, _syncQueue, classId: classId, studentId: studentId, data: data);

  @override
  ResultFuture<List<SchoolHistory>> getSchoolHistory({required String classId, required String studentId}) =>
      ops.getSchoolHistory(_localDataSource, _remoteDataSource, _dataEventBus, classId: classId, studentId: studentId);

  @override
  ResultFuture<SchoolHistory> createSchoolHistory({required String classId, required String studentId, required Map<String, dynamic> data}) =>
      ops.createSchoolHistory(_localDataSource, _syncQueue, classId: classId, studentId: studentId, data: data);

  @override
  ResultFuture<SchoolHistory> updateSchoolHistory({required String classId, required String studentId, required String historyId, required Map<String, dynamic> data}) =>
      ops.updateSchoolHistory(_localDataSource, _syncQueue, classId: classId, studentId: studentId, historyId: historyId, data: data);

  @override
  ResultFuture<void> deleteSchoolHistory({required String classId, required String studentId, required String historyId}) =>
      ops.deleteSchoolHistory(_localDataSource, _syncQueue, classId: classId, studentId: studentId, historyId: historyId);

  @override
  ResultFuture<List<PreviousSubject>> getPreviousSubjects({required String classId, required String studentId, String? schoolHistoryId}) =>
      ops.getPreviousSubjects(_localDataSource, _remoteDataSource, _dataEventBus, classId: classId, studentId: studentId, schoolHistoryId: schoolHistoryId);

  @override
  ResultFuture<PreviousSubject> upsertPreviousSubject({required String classId, required String studentId, required Map<String, dynamic> data}) =>
      ops.upsertPreviousSubject(_localDataSource, _syncQueue, classId: classId, studentId: studentId, data: data);

  @override
  ResultFuture<List<PreviousAttendance>> getPreviousAttendance({required String classId, required String studentId, String? schoolHistoryId}) =>
      ops.getPreviousAttendance(_localDataSource, _remoteDataSource, _dataEventBus, classId: classId, studentId: studentId, schoolHistoryId: schoolHistoryId);

  @override
  ResultFuture<PreviousAttendance> upsertPreviousAttendance({required String classId, required String studentId, required Map<String, dynamic> data}) =>
      ops.upsertPreviousAttendance(_localDataSource, _syncQueue, classId: classId, studentId: studentId, data: data);

  @override
  ResultFuture<Sf10Response> getSf10({required String classId, required String studentId}) =>
      ops.getSf10(_gradingLocalDataSource, _remoteDataSource, _dataEventBus, classId: classId, studentId: studentId);
}
