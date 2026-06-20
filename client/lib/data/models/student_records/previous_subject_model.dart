import 'package:likha/domain/student_records/entities/previous_subject.dart';

class PreviousSubjectModel extends PreviousSubject {
  const PreviousSubjectModel({
    required super.id,
    required super.studentId,
    required super.schoolHistoryId,
    required super.subjectName,
    super.subjectGroup,
    super.q1Grade,
    super.q2Grade,
    super.q3Grade,
    super.q4Grade,
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
      q1Grade: json['q1_grade'] as int?,
      q2Grade: json['q2_grade'] as int?,
      q3Grade: json['q3_grade'] as int?,
      q4Grade: json['q4_grade'] as int?,
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
    'q1_grade': q1Grade,
    'q2_grade': q2Grade,
    'q3_grade': q3Grade,
    'q4_grade': q4Grade,
    'final_grade': finalGrade,
    'descriptor': descriptor,
  };
}
