import 'package:equatable/equatable.dart';

class PreviousSubject extends Equatable {
  final String id;
  final String studentId;
  final String schoolHistoryId;
  final String subjectName;
  final String? subjectGroup;
  final String? termType;
  final List<int?> termGrades;
  final int? finalGrade;
  final String? descriptor;

  const PreviousSubject({
    required this.id,
    required this.studentId,
    required this.schoolHistoryId,
    required this.subjectName,
    this.subjectGroup,
    this.termType,
    this.termGrades = const [],
    this.finalGrade,
    this.descriptor,
  });

  @override
  List<Object?> get props => [id];
}
