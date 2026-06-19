import 'package:likha/domain/student_records/entities/school_history.dart';

class SchoolHistoryModel extends SchoolHistory {
  const SchoolHistoryModel({
    required super.id,
    required super.studentId,
    required super.schoolName,
    super.schoolId,
    required super.gradeLevel,
    required super.schoolYear,
    super.section,
    super.dateFrom,
    super.dateTo,
    required super.recordType,
  });

  factory SchoolHistoryModel.fromJson(Map<String, dynamic> json) {
    return SchoolHistoryModel(
      id: json['id'] as String,
      studentId: json['student_id'] as String,
      schoolName: json['school_name'] as String,
      schoolId: json['school_id'] as String?,
      gradeLevel: json['grade_level'] as String,
      schoolYear: json['school_year'] as String,
      section: json['section'] as String?,
      dateFrom: json['date_from'] as String?,
      dateTo: json['date_to'] as String?,
      recordType: json['record_type'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'student_id': studentId,
    'school_name': schoolName,
    'school_id': schoolId,
    'grade_level': gradeLevel,
    'school_year': schoolYear,
    'section': section,
    'date_from': dateFrom,
    'date_to': dateTo,
    'record_type': recordType,
  };
}
