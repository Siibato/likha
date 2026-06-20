import 'package:likha/core/utils/typedef.dart';
import 'package:likha/domain/student_records/entities/attendance_record.dart';
import 'package:likha/domain/student_records/repositories/student_records_repository.dart';

class GetAttendance {
  final StudentRecordsRepository _repository;
  GetAttendance(this._repository);

  ResultFuture<List<AttendanceRecord>> call(GetAttendanceParams params) {
    return _repository.getAttendance(classId: params.classId, studentId: params.studentId, schoolYear: params.schoolYear);
  }
}

class GetAttendanceParams {
  final String classId;
  final String studentId;
  final String? schoolYear;
  GetAttendanceParams({required this.classId, required this.studentId, this.schoolYear});
}
