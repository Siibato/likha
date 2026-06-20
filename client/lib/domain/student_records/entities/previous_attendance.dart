import 'package:equatable/equatable.dart';

class PreviousAttendance extends Equatable {
  final String id;
  final String studentId;
  final String schoolHistoryId;
  final String schoolYear;
  final String month;
  final int schoolDays;
  final int daysPresent;
  final int daysAbsent;

  const PreviousAttendance({
    required this.id,
    required this.studentId,
    required this.schoolHistoryId,
    required this.schoolYear,
    required this.month,
    required this.schoolDays,
    required this.daysPresent,
    required this.daysAbsent,
  });

  @override
  List<Object?> get props => [id];
}
