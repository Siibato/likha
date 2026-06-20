import 'package:likha/core/logging/sf9_logger.dart';
import 'package:likha/domain/grading/entities/sf9.dart';

class Sf9ResponseModel extends Sf9Response {
  const Sf9ResponseModel({
    required super.studentId,
    required super.studentName,
    super.gradeLevel,
    super.schoolYear,
    super.section,
    super.lrn,
    super.age,
    super.sex,
    super.trackStrand,
    super.curriculum,
    super.teacherName,
    super.gradingPeriodType,
    required super.subjects,
    super.generalAverage,
  });

  factory Sf9ResponseModel.fromJson(Map<String, dynamic> json) {
    final log = Sf9Logger.instance;
    log.log('Sf9ResponseModel.fromJson: keys = ${json.keys.toList()}');

    final studentId = json['student_id'] as String;
    final studentName = json['student_name'] as String;
    log.log('Sf9ResponseModel.fromJson: student_id=$studentId student_name=$studentName');

    final gradeLevel = json['grade_level'] as String?;
    final schoolYear = json['school_year'] as String?;
    final section = json['section'] as String?;
    final lrn = json['lrn'] as String?;
    final age = json['age'] as int?;
    final sex = json['sex'] as String?;
    final trackStrand = json['track_strand'] as String?;
    final curriculum = json['curriculum'] as String?;
    final teacherName = json['teacher_name'] as String?;
    final gradingPeriodType = json['grading_period_type'] as String?;

    log.log('Sf9ResponseModel.fromJson: grade_level=$gradeLevel school_year=$schoolYear section=$section lrn=$lrn age=$age sex=$sex track_strand=$trackStrand curriculum=$curriculum teacher_name=$teacherName grading_period_type=$gradingPeriodType');

    final subjectsRaw = json['subjects'] as List<dynamic>? ?? [];
    log.log('Sf9ResponseModel.fromJson: subjects raw count = ${subjectsRaw.length}');
    final subjects = subjectsRaw
        .map((e) => Sf9SubjectRowModel.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();

    final generalAverage = json['general_average'] != null
        ? Sf9PeriodAveragesModel.fromJson(Map<String, dynamic>.from(json['general_average'] as Map))
        : null;
    log.log('Sf9ResponseModel.fromJson: general_average = ${generalAverage != null ? 'present' : 'null'}');

    return Sf9ResponseModel(
      studentId: studentId,
      studentName: studentName,
      gradeLevel: gradeLevel,
      schoolYear: schoolYear,
      section: section,
      lrn: lrn,
      age: age,
      sex: sex,
      trackStrand: trackStrand,
      curriculum: curriculum,
      teacherName: teacherName,
      gradingPeriodType: gradingPeriodType,
      subjects: subjects,
      generalAverage: generalAverage,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'student_id': studentId,
      'student_name': studentName,
      'grade_level': gradeLevel,
      'school_year': schoolYear,
      'section': section,
      'lrn': lrn,
      'age': age,
      'sex': sex,
      'track_strand': trackStrand,
      'curriculum': curriculum,
      'teacher_name': teacherName,
      'grading_period_type': gradingPeriodType,
      'subjects': subjects.map((s) => (s as Sf9SubjectRowModel).toJson()).toList(),
      'general_average': generalAverage != null
          ? (generalAverage as Sf9PeriodAveragesModel).toJson()
          : null,
    };
  }
}

class Sf9SubjectRowModel extends Sf9SubjectRow {
  const Sf9SubjectRowModel({
    required super.classTitle,
    super.subjectGroup,
    super.periodGrades,
    super.finalGrade,
    super.descriptor,
  });

  factory Sf9SubjectRowModel.fromJson(Map<String, dynamic> json) {
    return Sf9SubjectRowModel(
      classTitle: json['class_title'] as String,
      subjectGroup: json['subject_group'] as String?,
      periodGrades: _parsePeriodGrades(json['period_grades']),
      finalGrade: json['final_grade'] as int?,
      descriptor: json['descriptor'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'class_title': classTitle,
      'subject_group': subjectGroup,
      'period_grades': periodGrades,
      'final_grade': finalGrade,
      'descriptor': descriptor,
    };
  }
}

class Sf9PeriodAveragesModel extends Sf9PeriodAverages {
  const Sf9PeriodAveragesModel({
    super.periodGrades,
    super.finalAverage,
    super.descriptor,
  });

  factory Sf9PeriodAveragesModel.fromJson(Map<String, dynamic> json) {
    return Sf9PeriodAveragesModel(
      periodGrades: _parsePeriodGrades(json['period_grades']),
      finalAverage: json['final_average'] as int?,
      descriptor: json['descriptor'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'period_grades': periodGrades,
      'final_average': finalAverage,
      'descriptor': descriptor,
    };
  }
}

List<int?> _parsePeriodGrades(dynamic value) {
  if (value == null) return const [];
  if (value is List) {
    return value.map((e) => e as int?).toList();
  }
  return const [];
}
