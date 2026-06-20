import 'package:equatable/equatable.dart';

class PreviousSubject extends Equatable {
  final String id;
  final String studentId;
  final String schoolHistoryId;
  final String subjectName;
  final String? subjectGroup;
  final int? q1Grade;
  final int? q2Grade;
  final int? q3Grade;
  final int? q4Grade;
  final int? finalGrade;
  final String? descriptor;

  const PreviousSubject({
    required this.id,
    required this.studentId,
    required this.schoolHistoryId,
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
  List<Object?> get props => [id];
}
