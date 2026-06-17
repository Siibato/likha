import 'package:likha/domain/grading/entities/general_average.dart';

class GeneralAverageResponseModel extends GeneralAverageResponse {
  const GeneralAverageResponseModel({
    required super.classId,
    required super.students,
  });

  factory GeneralAverageResponseModel.fromJson(Map<String, dynamic> json) {
    return GeneralAverageResponseModel(
      classId: json['class_id'] as String,
      students: (json['students'] as List<dynamic>? ?? [])
          .map((e) => StudentGeneralAverageModel.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'class_id': classId,
      'students': students.map((s) => (s as StudentGeneralAverageModel).toJson()).toList(),
    };
  }
}

class StudentGeneralAverageModel extends StudentGeneralAverage {
  const StudentGeneralAverageModel({
    required super.studentId,
    required super.studentName,
    super.generalAverage,
    required super.subjectCount,
    required super.subjects,
  });

  factory StudentGeneralAverageModel.fromJson(Map<String, dynamic> json) {
    return StudentGeneralAverageModel(
      studentId: json['student_id'] as String,
      studentName: json['student_name'] as String,
      generalAverage: json['general_average'] as int?,
      subjectCount: json['subject_count'] as int? ?? 0,
      subjects: (json['subjects'] as List<dynamic>? ?? [])
          .map((e) => SubjectGradeModel.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'student_id': studentId,
      'student_name': studentName,
      'general_average': generalAverage,
      'subject_count': subjectCount,
      'subjects': subjects.map((s) => (s as SubjectGradeModel).toJson()).toList(),
    };
  }
}

class SubjectGradeModel extends SubjectGrade {
  const SubjectGradeModel({
    required super.classId,
    required super.classTitle,
    super.finalGrade,
  });

  factory SubjectGradeModel.fromJson(Map<String, dynamic> json) {
    return SubjectGradeModel(
      classId: json['class_id'] as String,
      classTitle: json['class_title'] as String,
      finalGrade: json['final_grade'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'class_id': classId,
      'class_title': classTitle,
      'final_grade': finalGrade,
    };
  }
}
