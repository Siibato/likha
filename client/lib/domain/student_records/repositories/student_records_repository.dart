import 'package:likha/core/utils/typedef.dart';
import 'package:likha/domain/student_records/entities/learner_details.dart';
import 'package:likha/domain/student_records/entities/attendance_record.dart';
import 'package:likha/domain/student_records/entities/core_values_record.dart';
import 'package:likha/domain/student_records/entities/school_history.dart';
import 'package:likha/domain/student_records/entities/previous_subject.dart';
import 'package:likha/domain/student_records/entities/previous_attendance.dart';
import 'package:likha/domain/student_records/entities/sf10_response.dart';

abstract class StudentRecordsRepository {
  ResultFuture<LearnerDetails?> getLearnerDetails({required String classId, required String studentId});
  ResultFuture<LearnerDetails> upsertLearnerDetails({required String classId, required String studentId, required Map<String, dynamic> data});
  ResultFuture<List<AttendanceRecord>> getAttendance({required String classId, required String studentId, String? schoolYear});
  ResultFuture<AttendanceRecord> upsertAttendance({required String classId, required String studentId, required Map<String, dynamic> data});
  ResultFuture<List<CoreValuesRecord>> getCoreValues({required String classId, required String studentId, String? schoolYear});
  ResultFuture<CoreValuesRecord> upsertCoreValues({required String classId, required String studentId, required Map<String, dynamic> data});
  ResultFuture<List<SchoolHistory>> getSchoolHistory({required String classId, required String studentId});
  ResultFuture<SchoolHistory> createSchoolHistory({required String classId, required String studentId, required Map<String, dynamic> data});
  ResultFuture<SchoolHistory> updateSchoolHistory({required String classId, required String studentId, required String historyId, required Map<String, dynamic> data});
  ResultFuture<void> deleteSchoolHistory({required String classId, required String studentId, required String historyId});
  ResultFuture<List<PreviousSubject>> getPreviousSubjects({required String classId, required String studentId, String? schoolHistoryId});
  ResultFuture<PreviousSubject> upsertPreviousSubject({required String classId, required String studentId, required Map<String, dynamic> data});
  ResultFuture<List<PreviousAttendance>> getPreviousAttendance({required String classId, required String studentId, String? schoolHistoryId});
  ResultFuture<PreviousAttendance> upsertPreviousAttendance({required String classId, required String studentId, required Map<String, dynamic> data});
  ResultFuture<Sf10Response> getSf10({required String classId, required String studentId});
}
