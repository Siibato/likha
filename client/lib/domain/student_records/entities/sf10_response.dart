import 'package:equatable/equatable.dart';

class Sf10Response extends Equatable {
  final String studentId;
  final String studentName;
  final String? lrn;
  final String? birthdate;
  final String? birthplace;
  final String? homeAddress;
  final String? sex;
  final int? age;
  final String? fatherName;
  final String? motherName;
  final String? guardianName;
  final String? guardianContact;
  final String? trackStrand;
  final String? curriculum;
  final String? currentSchoolYear;
  final String? currentGradeLevel;
  final String? currentSection;
  final List<Sf10SchoolHistory> schoolHistory;
  final List<Sf10YearRecord> scholasticRecords;

  const Sf10Response({
    required this.studentId,
    required this.studentName,
    this.lrn,
    this.birthdate,
    this.birthplace,
    this.homeAddress,
    this.sex,
    this.age,
    this.fatherName,
    this.motherName,
    this.guardianName,
    this.guardianContact,
    this.trackStrand,
    this.curriculum,
    this.currentSchoolYear,
    this.currentGradeLevel,
    this.currentSection,
    this.schoolHistory = const [],
    this.scholasticRecords = const [],
  });

  @override
  List<Object?> get props => [studentId];
}

class Sf10SchoolHistory extends Equatable {
  final String id;
  final String schoolName;
  final String? schoolId;
  final String gradeLevel;
  final String schoolYear;
  final String? section;
  final String? dateFrom;
  final String? dateTo;
  final String recordType;
  final List<Sf10PreviousSubject> subjects;
  final List<Sf10AttendanceMonth> attendance;

  const Sf10SchoolHistory({
    required this.id,
    required this.schoolName,
    this.schoolId,
    required this.gradeLevel,
    required this.schoolYear,
    this.section,
    this.dateFrom,
    this.dateTo,
    required this.recordType,
    this.subjects = const [],
    this.attendance = const [],
  });

  @override
  List<Object?> get props => [id];
}

class Sf10YearRecord extends Equatable {
  final String schoolYear;
  final String gradeLevel;
  final String? section;
  final String schoolName;
  final List<Sf10SubjectRow> subjects;
  final int? finalAverage;
  final String? descriptor;
  final List<Sf10AttendanceMonth> attendance;

  const Sf10YearRecord({
    required this.schoolYear,
    required this.gradeLevel,
    this.section,
    required this.schoolName,
    this.subjects = const [],
    this.finalAverage,
    this.descriptor,
    this.attendance = const [],
  });

  @override
  List<Object?> get props => [schoolYear, gradeLevel];
}

class Sf10SubjectRow extends Equatable {
  final String classTitle;
  final String? subjectGroup;
  final List<int?> termGrades;
  final int? finalGrade;
  final String? descriptor;

  const Sf10SubjectRow({
    required this.classTitle,
    this.subjectGroup,
    this.termGrades = const [],
    this.finalGrade,
    this.descriptor,
  });

  @override
  List<Object?> get props => [classTitle, finalGrade];
}

class Sf10PreviousSubject extends Equatable {
  final String subjectName;
  final String? subjectGroup;
  final int? q1Grade;
  final int? q2Grade;
  final int? q3Grade;
  final int? q4Grade;
  final int? finalGrade;
  final String? descriptor;

  const Sf10PreviousSubject({
    required this.subjectName,
    this.subjectGroup,
    this.q1Grade,
    this.q2Grade,
    this.q3Grade,
    this.q4Grade,
    this.finalGrade,
    this.descriptor,
  });

  @override
  List<Object?> get props => [subjectName, finalGrade];
}

class Sf10AttendanceMonth extends Equatable {
  final String month;
  final int schoolDays;
  final int daysPresent;
  final int daysAbsent;

  const Sf10AttendanceMonth({
    required this.month,
    required this.schoolDays,
    required this.daysPresent,
    required this.daysAbsent,
  });

  @override
  List<Object?> get props => [month];
}
