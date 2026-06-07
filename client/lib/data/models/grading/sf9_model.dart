import 'package:likha/domain/grading/entities/sf9.dart';

class Sf9ResponseModel extends Sf9Response {
  const Sf9ResponseModel({
    required super.studentId,
    required super.studentName,
    super.gradeLevel,
    super.schoolYear,
    super.section,
    required super.subjects,
    super.generalAverage,
  });

  factory Sf9ResponseModel.fromJson(Map<String, dynamic> json) {
    return Sf9ResponseModel(
      studentId: json['student_id'] as String,
      studentName: json['student_name'] as String,
      gradeLevel: json['grade_level'] as String?,
      schoolYear: json['school_year'] as String?,
      section: json['section'] as String?,
      subjects: (json['subjects'] as List<dynamic>? ?? [])
          .map((e) => Sf9SubjectRowModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      generalAverage: json['general_average'] != null
          ? Sf9QuarterlyAveragesModel.fromJson(json['general_average'] as Map<String, dynamic>)
          : null,
    );
  }
}

class Sf9SubjectRowModel extends Sf9SubjectRow {
  const Sf9SubjectRowModel({
    required super.classTitle,
    super.subjectGroup,
    super.q1,
    super.q2,
    super.q3,
    super.q4,
    super.finalGrade,
    super.descriptor,
  });

  factory Sf9SubjectRowModel.fromJson(Map<String, dynamic> json) {
    return Sf9SubjectRowModel(
      classTitle: json['class_title'] as String,
      subjectGroup: json['subject_group'] as String?,
      q1: json['q1'] as int?,
      q2: json['q2'] as int?,
      q3: json['q3'] as int?,
      q4: json['q4'] as int?,
      finalGrade: json['final_grade'] as int?,
      descriptor: json['descriptor'] as String?,
    );
  }
}

class Sf9QuarterlyAveragesModel extends Sf9QuarterlyAverages {
  const Sf9QuarterlyAveragesModel({
    super.q1,
    super.q2,
    super.q3,
    super.q4,
    super.finalAverage,
    super.descriptor,
  });

  factory Sf9QuarterlyAveragesModel.fromJson(Map<String, dynamic> json) {
    return Sf9QuarterlyAveragesModel(
      q1: json['q1'] as int?,
      q2: json['q2'] as int?,
      q3: json['q3'] as int?,
      q4: json['q4'] as int?,
      finalAverage: json['final_average'] as int?,
      descriptor: json['descriptor'] as String?,
    );
  }
}
