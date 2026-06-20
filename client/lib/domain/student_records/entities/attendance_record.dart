import 'package:equatable/equatable.dart';

class AttendanceRecord extends Equatable {
  final String id;
  final String studentId;
  final String classId;
  final String schoolYear;
  final String month;
  final int schoolDays;
  final int daysPresent;
  final int daysAbsent;

  const AttendanceRecord({
    required this.id,
    required this.studentId,
    required this.classId,
    required this.schoolYear,
    required this.month,
    required this.schoolDays,
    required this.daysPresent,
    required this.daysAbsent,
  });

  @override
  List<Object?> get props => [id];
}
