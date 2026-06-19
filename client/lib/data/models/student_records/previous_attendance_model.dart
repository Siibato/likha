import 'package:likha/domain/student_records/entities/previous_attendance.dart';

class PreviousAttendanceModel extends PreviousAttendance {
  const PreviousAttendanceModel({
    required super.id,
    required super.studentId,
    required super.schoolHistoryId,
    required super.schoolYear,
    required super.month,
    required super.schoolDays,
    required super.daysPresent,
    required super.daysAbsent,
  });

  factory PreviousAttendanceModel.fromJson(Map<String, dynamic> json) {
    return PreviousAttendanceModel(
      id: json['id'] as String,
      studentId: json['student_id'] as String,
      schoolHistoryId: json['school_history_id'] as String,
      schoolYear: json['school_year'] as String,
      month: json['month'] as String,
      schoolDays: json['school_days'] as int,
      daysPresent: json['days_present'] as int,
      daysAbsent: json['days_absent'] as int,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'student_id': studentId,
    'school_history_id': schoolHistoryId,
    'school_year': schoolYear,
    'month': month,
    'school_days': schoolDays,
    'days_present': daysPresent,
    'days_absent': daysAbsent,
  };
}
