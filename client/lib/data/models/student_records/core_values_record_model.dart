import 'package:likha/domain/student_records/entities/core_values_record.dart';

class CoreValuesRecordModel extends CoreValuesRecord {
  const CoreValuesRecordModel({
    required super.id,
    required super.studentId,
    required super.classId,
    required super.schoolYear,
    required super.termNumber,
    required super.coreValueId,
    required super.marking,
  });

  factory CoreValuesRecordModel.fromJson(Map<String, dynamic> json) {
    return CoreValuesRecordModel(
      id: json['id'] as String,
      studentId: json['student_id'] as String,
      classId: json['class_id'] as String,
      schoolYear: json['school_year'] as String,
      termNumber: json['term_number'] as int,
      coreValueId: json['core_value_id'] as int,
      marking: json['marking'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'student_id': studentId,
    'class_id': classId,
    'school_year': schoolYear,
    'term_number': termNumber,
    'core_value_id': coreValueId,
    'marking': marking,
  };
}
