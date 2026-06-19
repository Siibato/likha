import 'package:likha/core/constants/api_endpoints.dart';
import 'package:likha/core/network/dio_client.dart';
import 'package:likha/data/models/student_records/learner_details_model.dart';
import 'package:likha/data/models/student_records/attendance_record_model.dart';
import 'package:likha/data/models/student_records/core_values_record_model.dart';
import 'package:likha/data/models/student_records/school_history_model.dart';
import 'package:likha/data/models/student_records/previous_subject_model.dart';
import 'package:likha/data/models/student_records/previous_attendance_model.dart';
import 'package:likha/data/models/student_records/sf10_response_model.dart';

abstract class StudentRecordsRemoteDataSource {
  Future<LearnerDetailsModel> getLearnerDetails({required String classId, required String studentId});
  Future<LearnerDetailsModel> upsertLearnerDetails({required String classId, required String studentId, required Map<String, dynamic> data});
  Future<List<AttendanceRecordModel>> getAttendance({required String classId, required String studentId, String? classIdFilter, String? schoolYear});
  Future<AttendanceRecordModel> upsertAttendance({required String classId, required String studentId, required Map<String, dynamic> data});
  Future<List<CoreValuesRecordModel>> getCoreValues({required String classId, required String studentId, String? classIdFilter, String? schoolYear});
  Future<CoreValuesRecordModel> upsertCoreValues({required String classId, required String studentId, required Map<String, dynamic> data});
  Future<List<SchoolHistoryModel>> getSchoolHistory({required String classId, required String studentId});
  Future<SchoolHistoryModel> createSchoolHistory({required String classId, required String studentId, required Map<String, dynamic> data});
  Future<SchoolHistoryModel> updateSchoolHistory({required String classId, required String studentId, required String historyId, required Map<String, dynamic> data});
  Future<void> deleteSchoolHistory({required String classId, required String studentId, required String historyId});
  Future<List<PreviousSubjectModel>> getPreviousSubjects({required String classId, required String studentId, String? schoolHistoryId});
  Future<PreviousSubjectModel> upsertPreviousSubject({required String classId, required String studentId, required Map<String, dynamic> data});
  Future<List<PreviousAttendanceModel>> getPreviousAttendance({required String classId, required String studentId, String? schoolHistoryId});
  Future<PreviousAttendanceModel> upsertPreviousAttendance({required String classId, required String studentId, required Map<String, dynamic> data});
  Future<Sf10ResponseModel> getSf10({required String classId, required String studentId});
}

class StudentRecordsRemoteDataSourceImpl implements StudentRecordsRemoteDataSource {
  final DioClient _dioClient;

  StudentRecordsRemoteDataSourceImpl(this._dioClient);

  @override
  Future<LearnerDetailsModel> getLearnerDetails({required String classId, required String studentId}) =>
      _dioClient.getTyped(ApiEndpoints.learnerDetails(classId, studentId));

  @override
  Future<LearnerDetailsModel> upsertLearnerDetails({required String classId, required String studentId, required Map<String, dynamic> data}) =>
      _dioClient.putTyped(ApiEndpoints.learnerDetails(classId, studentId), data: data);

  @override
  Future<List<AttendanceRecordModel>> getAttendance({required String classId, required String studentId, String? classIdFilter, String? schoolYear}) {
    final qp = <String, dynamic>{};
    if (classIdFilter != null) qp['class_id'] = classIdFilter;
    if (schoolYear != null) qp['school_year'] = schoolYear;
    return _dioClient.getTyped(ApiEndpoints.attendance(classId, studentId), queryParameters: qp.isNotEmpty ? qp : null);
  }

  @override
  Future<AttendanceRecordModel> upsertAttendance({required String classId, required String studentId, required Map<String, dynamic> data}) =>
      _dioClient.putTyped(ApiEndpoints.attendanceUpsert(classId, studentId), data: data);

  @override
  Future<List<CoreValuesRecordModel>> getCoreValues({required String classId, required String studentId, String? classIdFilter, String? schoolYear}) {
    final qp = <String, dynamic>{};
    if (classIdFilter != null) qp['class_id'] = classIdFilter;
    if (schoolYear != null) qp['school_year'] = schoolYear;
    return _dioClient.getTyped(ApiEndpoints.coreValues(classId, studentId), queryParameters: qp.isNotEmpty ? qp : null);
  }

  @override
  Future<CoreValuesRecordModel> upsertCoreValues({required String classId, required String studentId, required Map<String, dynamic> data}) =>
      _dioClient.putTyped(ApiEndpoints.coreValuesUpsert(classId, studentId), data: data);

  @override
  Future<List<SchoolHistoryModel>> getSchoolHistory({required String classId, required String studentId}) =>
      _dioClient.getTyped(ApiEndpoints.schoolHistory(classId, studentId));

  @override
  Future<SchoolHistoryModel> createSchoolHistory({required String classId, required String studentId, required Map<String, dynamic> data}) =>
      _dioClient.postTyped(ApiEndpoints.schoolHistoryCreate(classId, studentId), data: data);

  @override
  Future<SchoolHistoryModel> updateSchoolHistory({required String classId, required String studentId, required String historyId, required Map<String, dynamic> data}) =>
      _dioClient.putTyped(ApiEndpoints.schoolHistoryUpdate(classId, studentId, historyId), data: data);

  @override
  Future<void> deleteSchoolHistory({required String classId, required String studentId, required String historyId}) =>
      _dioClient.deleteTyped(ApiEndpoints.schoolHistoryDelete(classId, studentId, historyId));

  @override
  Future<List<PreviousSubjectModel>> getPreviousSubjects({required String classId, required String studentId, String? schoolHistoryId}) {
    final qp = <String, dynamic>{};
    if (schoolHistoryId != null) qp['class_id'] = schoolHistoryId;
    return _dioClient.getTyped(ApiEndpoints.previousSubjects(classId, studentId), queryParameters: qp.isNotEmpty ? qp : null);
  }

  @override
  Future<PreviousSubjectModel> upsertPreviousSubject({required String classId, required String studentId, required Map<String, dynamic> data}) =>
      _dioClient.putTyped(ApiEndpoints.previousSubjectUpsert(classId, studentId), data: data);

  @override
  Future<List<PreviousAttendanceModel>> getPreviousAttendance({required String classId, required String studentId, String? schoolHistoryId}) {
    final qp = <String, dynamic>{};
    if (schoolHistoryId != null) qp['class_id'] = schoolHistoryId;
    return _dioClient.getTyped(ApiEndpoints.previousAttendance(classId, studentId), queryParameters: qp.isNotEmpty ? qp : null);
  }

  @override
  Future<PreviousAttendanceModel> upsertPreviousAttendance({required String classId, required String studentId, required Map<String, dynamic> data}) =>
      _dioClient.putTyped(ApiEndpoints.previousAttendanceUpsert(classId, studentId), data: data);

  @override
  Future<Sf10ResponseModel> getSf10({required String classId, required String studentId}) =>
      _dioClient.getTyped(ApiEndpoints.sf10V2(classId, studentId));
}
