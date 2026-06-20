import 'package:equatable/equatable.dart';

class SchoolHistory extends Equatable {
  final String id;
  final String studentId;
  final String schoolName;
  final String? schoolId;
  final String gradeLevel;
  final String schoolYear;
  final String? section;
  final String? dateFrom;
  final String? dateTo;
  final String recordType;

  const SchoolHistory({
    required this.id,
    required this.studentId,
    required this.schoolName,
    this.schoolId,
    required this.gradeLevel,
    required this.schoolYear,
    this.section,
    this.dateFrom,
    this.dateTo,
    required this.recordType,
  });

  @override
  List<Object?> get props => [id];
}
