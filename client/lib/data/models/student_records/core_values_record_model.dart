import 'package:likha/domain/student_records/entities/core_values_record.dart';

class CoreValuesRecordModel extends CoreValuesRecord {
  const CoreValuesRecordModel({
    required super.id,
    required super.studentId,
    required super.classId,
    required super.schoolYear,
    required super.gradingPeriodNumber,
    required super.coreValue,
    required super.behaviorStatement,
    required super.marking,
  });

  factory CoreValuesRecordModel.fromJson(Map<String, dynamic> json) {
    return CoreValuesRecordModel(
      id: json['id'] as String,
      studentId: json['student_id'] as String,
      classId: json['class_id'] as String,
      schoolYear: json['school_year'] as String,
      gradingPeriodNumber: json['grading_period_number'] as int,
      coreValue: json['core_value'] as String,
      behaviorStatement: json['behavior_statement'] as String,
      marking: json['marking'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'student_id': studentId,
    'class_id': classId,
    'school_year': schoolYear,
    'grading_period_number': gradingPeriodNumber,
    'core_value': coreValue,
    'behavior_statement': behaviorStatement,
    'marking': marking,
  };
}
