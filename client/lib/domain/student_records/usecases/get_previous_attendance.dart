import 'package:likha/core/utils/typedef.dart';
import 'package:likha/domain/student_records/entities/previous_attendance.dart';
import 'package:likha/domain/student_records/repositories/student_records_repository.dart';

class GetPreviousAttendance {
  final StudentRecordsRepository _repository;
  GetPreviousAttendance(this._repository);

  ResultFuture<List<PreviousAttendance>> call(GetPreviousAttendanceParams params) {
    return _repository.getPreviousAttendance(
      classId: params.classId,
      studentId: params.studentId,
      schoolHistoryId: params.schoolHistoryId,
    );
  }
}

class GetPreviousAttendanceParams {
  final String classId;
  final String studentId;
  final String? schoolHistoryId;
  GetPreviousAttendanceParams({required this.classId, required this.studentId, this.schoolHistoryId});
}
