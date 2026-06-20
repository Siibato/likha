import 'package:likha/core/utils/typedef.dart';
import 'package:likha/domain/student_records/entities/previous_attendance.dart';
import 'package:likha/domain/student_records/repositories/student_records_repository.dart';

class UpsertPreviousAttendance {
  final StudentRecordsRepository _repository;
  UpsertPreviousAttendance(this._repository);

  ResultFuture<PreviousAttendance> call(UpsertPreviousAttendanceParams params) {
    return _repository.upsertPreviousAttendance(
      classId: params.classId,
      studentId: params.studentId,
      data: params.data,
    );
  }
}

class UpsertPreviousAttendanceParams {
  final String classId;
  final String studentId;
  final Map<String, dynamic> data;
  UpsertPreviousAttendanceParams({required this.classId, required this.studentId, required this.data});
}
