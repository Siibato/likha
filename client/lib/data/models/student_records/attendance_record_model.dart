import 'package:likha/domain/student_records/entities/attendance_record.dart';

class AttendanceRecordModel extends AttendanceRecord {
  const AttendanceRecordModel({
    required super.id,
    required super.studentId,
    required super.classId,
    required super.schoolYear,
    required super.month,
    required super.schoolDays,
    required super.daysPresent,
  });

  factory AttendanceRecordModel.fromJson(Map<String, dynamic> json) {
    return AttendanceRecordModel(
      id: json['id'] as String,
      studentId: json['student_id'] as String,
      classId: json['class_id'] as String,
      schoolYear: json['school_year'] as String,
      month: json['month'] as String,
      schoolDays: json['school_days'] as int,
      daysPresent: json['days_present'] as int,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'student_id': studentId,
    'class_id': classId,
    'school_year': schoolYear,
    'month': month,
    'school_days': schoolDays,
    'days_present': daysPresent,
  };
}
