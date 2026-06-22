import 'package:likha/domain/student_records/entities/previous_subject.dart';

class PreviousSubjectModel extends PreviousSubject {
  const PreviousSubjectModel({
    required super.id,
    required super.studentId,
    required super.schoolHistoryId,
    required super.subjectName,
    super.subjectGroup,
    super.termType,
    super.termGrades = const [],
    super.finalGrade,
    super.descriptor,
  });

  factory PreviousSubjectModel.fromJson(Map<String, dynamic> json) {
    return PreviousSubjectModel(
      id: json['id'] as String,
      studentId: json['student_id'] as String,
      schoolHistoryId: json['school_history_id'] as String,
      subjectName: json['subject_name'] as String,
      subjectGroup: json['subject_group'] as String?,
      termType: json['term_type'] as String?,
      termGrades: (json['term_grades'] as List<dynamic>?)
          ?.map((e) => e as int?)
          .toList() ??
          const [],
      finalGrade: json['final_grade'] as int?,
      descriptor: json['descriptor'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'student_id': studentId,
    'school_history_id': schoolHistoryId,
    'subject_name': subjectName,
    'subject_group': subjectGroup,
    'term_type': termType,
    'term_grades': termGrades,
    'final_grade': finalGrade,
    'descriptor': descriptor,
  };
}
