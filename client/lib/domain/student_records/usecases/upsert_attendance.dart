import 'package:likha/core/utils/typedef.dart';
import 'package:likha/domain/student_records/entities/attendance_record.dart';
import 'package:likha/domain/student_records/repositories/student_records_repository.dart';

class UpsertAttendance {
  final StudentRecordsRepository _repository;
  UpsertAttendance(this._repository);

  ResultFuture<AttendanceRecord> call(UpsertAttendanceParams params) {
    return _repository.upsertAttendance(classId: params.classId, studentId: params.studentId, data: params.data);
  }
}

class UpsertAttendanceParams {
  final String classId;
  final String studentId;
  final Map<String, dynamic> data;
  UpsertAttendanceParams({required this.classId, required this.studentId, required this.data});
}
