import 'package:equatable/equatable.dart';

class GradeConfig extends Equatable {
  final String id;
  final String classId;
  final int gradingPeriodNumber;
  final double wwWeight;
  final double ptWeight;
  final double qaWeight;

  const GradeConfig({
    required this.id,
    required this.classId,
    required this.gradingPeriodNumber,
    required this.wwWeight,
    required this.ptWeight,
    required this.qaWeight,
  });

  @override
  List<Object?> get props => [
        id,
        classId,
        gradingPeriodNumber,
        wwWeight,
        ptWeight,
        qaWeight,
      ];
}
