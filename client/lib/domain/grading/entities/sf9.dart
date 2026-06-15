import 'package:equatable/equatable.dart';

class Sf9Response extends Equatable {
  final String studentId;
  final String studentName;
  final String? gradeLevel;
  final String? schoolYear;
  final String? section;
  final List<Sf9SubjectRow> subjects;
  final Sf9QuarterlyAverages? generalAverage;

  const Sf9Response({
    required this.studentId,
    required this.studentName,
    this.gradeLevel,
    this.schoolYear,
    this.section,
    required this.subjects,
    this.generalAverage,
  });

  @override
  List<Object?> get props => [studentId];
}

class Sf9SubjectRow extends Equatable {
  final String classTitle;
  final String? subjectGroup;
  final int? q1;
  final int? q2;
  final int? q3;
  final int? q4;
  final int? finalGrade;
  final String? descriptor;

  const Sf9SubjectRow({
    required this.classTitle,
    this.subjectGroup,
    this.q1,
    this.q2,
    this.q3,
    this.q4,
    this.finalGrade,
    this.descriptor,
  });

  @override
  List<Object?> get props => [classTitle, finalGrade];
}

class Sf9QuarterlyAverages extends Equatable {
  final int? q1;
  final int? q2;
  final int? q3;
  final int? q4;
  final int? finalAverage;
  final String? descriptor;

  const Sf9QuarterlyAverages({
    this.q1,
    this.q2,
    this.q3,
    this.q4,
    this.finalAverage,
    this.descriptor,
  });

  @override
  List<Object?> get props => [finalAverage];
}
