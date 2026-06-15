import 'package:equatable/equatable.dart';

class GeneralAverageResponse extends Equatable {
  final String classId;
  final List<StudentGeneralAverage> students;

  const GeneralAverageResponse({
    required this.classId,
    required this.students,
  });

  @override
  List<Object?> get props => [classId];
}

class StudentGeneralAverage extends Equatable {
  final String studentId;
  final String studentName;
  final int? generalAverage;
  final int subjectCount;
  final List<SubjectGrade> subjects;

  const StudentGeneralAverage({
    required this.studentId,
    required this.studentName,
    this.generalAverage,
    required this.subjectCount,
    required this.subjects,
  });

  @override
  List<Object?> get props => [studentId, generalAverage];
}

class SubjectGrade extends Equatable {
  final String classId;
  final String classTitle;
  final int? finalGrade;

  const SubjectGrade({
    required this.classId,
    required this.classTitle,
    this.finalGrade,
  });

  @override
  List<Object?> get props => [classId, finalGrade];
}
