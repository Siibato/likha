import 'package:equatable/equatable.dart';

class Sf9Response extends Equatable {
  final String studentId;
  final String studentName;
  final String? gradeLevel;
  final String? schoolYear;
  final String? section;
  final String? lrn;
  final int? age;
  final String? sex;
  final String? trackStrand;
  final String? curriculum;
  final String? teacherName;
  final String? gradingPeriodType;
  final List<Sf9SubjectRow> subjects;
  final Sf9PeriodAverages? generalAverage;

  const Sf9Response({
    required this.studentId,
    required this.studentName,
    this.gradeLevel,
    this.schoolYear,
    this.section,
    this.lrn,
    this.age,
    this.sex,
    this.trackStrand,
    this.curriculum,
    this.teacherName,
    this.gradingPeriodType,
    required this.subjects,
    this.generalAverage,
  });

  @override
  List<Object?> get props => [studentId];
}

class Sf9SubjectRow extends Equatable {
  final String classTitle;
  final String? subjectGroup;
  final List<int?> periodGrades;
  final int? finalGrade;
  final String? descriptor;

  const Sf9SubjectRow({
    required this.classTitle,
    this.subjectGroup,
    this.periodGrades = const [],
    this.finalGrade,
    this.descriptor,
  });

  @override
  List<Object?> get props => [classTitle, finalGrade];
}

class Sf9PeriodAverages extends Equatable {
  final List<int?> periodGrades;
  final int? finalAverage;
  final String? descriptor;

  const Sf9PeriodAverages({
    this.periodGrades = const [],
    this.finalAverage,
    this.descriptor,
  });

  @override
  List<Object?> get props => [finalAverage];
}
