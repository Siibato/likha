import 'package:likha/core/database/local_database.dart';
import 'package:likha/core/sync/sync_queue.dart';
import 'package:likha/data/models/student_records/learner_details_model.dart';
import 'package:likha/data/models/student_records/attendance_record_model.dart';
import 'package:likha/data/models/student_records/core_values_record_model.dart';
import 'package:likha/data/models/student_records/school_history_model.dart';
import 'package:likha/data/models/student_records/previous_subject_model.dart';
import 'package:likha/data/models/student_records/previous_attendance_model.dart';
import 'operations/student_records_ops.dart' as ops;

abstract class StudentRecordsLocalDataSource {
  LocalDatabase get localDatabase;

  Future<LearnerDetailsModel?> getCachedLearnerDetails(String userId);
  Future<void> cacheLearnerDetails(LearnerDetailsModel model, {Transaction? txn});
  Future<void> insertLearnerDetails(LearnerDetailsModel model, {Transaction? txn});

  Future<List<AttendanceRecordModel>> getCachedAttendance(String studentId, {String? classId, String? schoolYear});
  Future<void> cacheAttendance(List<AttendanceRecordModel> records, {Transaction? txn});
  Future<void> insertAttendance(AttendanceRecordModel model, {Transaction? txn});

  Future<List<CoreValuesRecordModel>> getCachedCoreValues(String studentId, {String? classId, String? schoolYear});
  Future<void> cacheCoreValues(List<CoreValuesRecordModel> records, {Transaction? txn});
  Future<void> insertCoreValues(CoreValuesRecordModel model, {Transaction? txn});

  Future<List<SchoolHistoryModel>> getCachedSchoolHistory(String studentId);
  Future<void> cacheSchoolHistory(List<SchoolHistoryModel> records, {Transaction? txn});
  Future<void> insertSchoolHistory(SchoolHistoryModel model, {Transaction? txn});
  Future<void> updateSchoolHistory(SchoolHistoryModel model, {Transaction? txn});
  Future<void> deleteSchoolHistory(String historyId, {Transaction? txn});

  Future<List<PreviousSubjectModel>> getCachedPreviousSubjects(String studentId, {String? schoolHistoryId});
  Future<void> cachePreviousSubjects(List<PreviousSubjectModel> records, {Transaction? txn});
  Future<void> insertPreviousSubject(PreviousSubjectModel model, {Transaction? txn});

  Future<List<PreviousAttendanceModel>> getCachedPreviousAttendance(String studentId, {String? schoolHistoryId});
  Future<void> cachePreviousAttendance(List<PreviousAttendanceModel> records, {Transaction? txn});
  Future<void> insertPreviousAttendance(PreviousAttendanceModel model, {Transaction? txn});

  Future<void> clearAllCache();
}

class StudentRecordsLocalDataSourceImpl implements StudentRecordsLocalDataSource {
  @override
  final LocalDatabase localDatabase;

  StudentRecordsLocalDataSourceImpl(this.localDatabase);

  @override
  Future<LearnerDetailsModel?> getCachedLearnerDetails(String userId) =>
      ops.getCachedLearnerDetails(localDatabase, userId);

  @override
  Future<void> cacheLearnerDetails(LearnerDetailsModel model, {Transaction? txn}) =>
      ops.cacheLearnerDetails(localDatabase, model, txn: txn);

  @override
  Future<void> insertLearnerDetails(LearnerDetailsModel model, {Transaction? txn}) =>
      ops.insertLearnerDetails(localDatabase, model, txn: txn);

  @override
  Future<List<AttendanceRecordModel>> getCachedAttendance(String studentId, {String? classId, String? schoolYear}) =>
      ops.getCachedAttendance(localDatabase, studentId, classId: classId, schoolYear: schoolYear);

  @override
  Future<void> cacheAttendance(List<AttendanceRecordModel> records, {Transaction? txn}) =>
      ops.cacheAttendance(localDatabase, records, txn: txn);

  @override
  Future<void> insertAttendance(AttendanceRecordModel model, {Transaction? txn}) =>
      ops.insertAttendance(localDatabase, model, txn: txn);

  @override
  Future<List<CoreValuesRecordModel>> getCachedCoreValues(String studentId, {String? classId, String? schoolYear}) =>
      ops.getCachedCoreValues(localDatabase, studentId, classId: classId, schoolYear: schoolYear);

  @override
  Future<void> cacheCoreValues(List<CoreValuesRecordModel> records, {Transaction? txn}) =>
      ops.cacheCoreValues(localDatabase, records, txn: txn);

  @override
  Future<void> insertCoreValues(CoreValuesRecordModel model, {Transaction? txn}) =>
      ops.insertCoreValues(localDatabase, model, txn: txn);

  @override
  Future<List<SchoolHistoryModel>> getCachedSchoolHistory(String studentId) =>
      ops.getCachedSchoolHistory(localDatabase, studentId);

  @override
  Future<void> cacheSchoolHistory(List<SchoolHistoryModel> records, {Transaction? txn}) =>
      ops.cacheSchoolHistory(localDatabase, records, txn: txn);

  @override
  Future<void> insertSchoolHistory(SchoolHistoryModel model, {Transaction? txn}) =>
      ops.insertSchoolHistory(localDatabase, model, txn: txn);

  @override
  Future<void> updateSchoolHistory(SchoolHistoryModel model, {Transaction? txn}) =>
      ops.updateSchoolHistory(localDatabase, model, txn: txn);

  @override
  Future<void> deleteSchoolHistory(String historyId, {Transaction? txn}) =>
      ops.deleteSchoolHistory(localDatabase, historyId, txn: txn);

  @override
  Future<List<PreviousSubjectModel>> getCachedPreviousSubjects(String studentId, {String? schoolHistoryId}) =>
      ops.getCachedPreviousSubjects(localDatabase, studentId, schoolHistoryId: schoolHistoryId);

  @override
  Future<void> cachePreviousSubjects(List<PreviousSubjectModel> records, {Transaction? txn}) =>
      ops.cachePreviousSubjects(localDatabase, records, txn: txn);

  @override
  Future<void> insertPreviousSubject(PreviousSubjectModel model, {Transaction? txn}) =>
      ops.insertPreviousSubject(localDatabase, model, txn: txn);

  @override
  Future<List<PreviousAttendanceModel>> getCachedPreviousAttendance(String studentId, {String? schoolHistoryId}) =>
      ops.getCachedPreviousAttendance(localDatabase, studentId, schoolHistoryId: schoolHistoryId);

  @override
  Future<void> cachePreviousAttendance(List<PreviousAttendanceModel> records, {Transaction? txn}) =>
      ops.cachePreviousAttendance(localDatabase, records, txn: txn);

  @override
  Future<void> insertPreviousAttendance(PreviousAttendanceModel model, {Transaction? txn}) =>
      ops.insertPreviousAttendance(localDatabase, model, txn: txn);

  @override
  Future<void> clearAllCache() => ops.clearAllStudentRecordsCache(localDatabase);
}
