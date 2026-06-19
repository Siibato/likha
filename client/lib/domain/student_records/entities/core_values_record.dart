import 'package:equatable/equatable.dart';

class CoreValuesRecord extends Equatable {
  final String id;
  final String studentId;
  final String classId;
  final String schoolYear;
  final int gradingPeriodNumber;
  final String coreValue;
  final String behaviorStatement;
  final String marking;

  const CoreValuesRecord({
    required this.id,
    required this.studentId,
    required this.classId,
    required this.schoolYear,
    required this.gradingPeriodNumber,
    required this.coreValue,
    required this.behaviorStatement,
    required this.marking,
  });

  @override
  List<Object?> get props => [id];
}
