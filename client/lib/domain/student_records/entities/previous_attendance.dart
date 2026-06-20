import 'package:equatable/equatable.dart';

class PreviousAttendance extends Equatable {
  final String id;
  final String studentId;
  final String schoolHistoryId;
  final String schoolYear;
  final String month;
  final int schoolDays;
  final int daysPresent;

  const PreviousAttendance({
    required this.id,
    required this.studentId,
    required this.schoolHistoryId,
    required this.schoolYear,
    required this.month,
    required this.schoolDays,
    required this.daysPresent,
  });

  @override
  List<Object?> get props => [id];
}
