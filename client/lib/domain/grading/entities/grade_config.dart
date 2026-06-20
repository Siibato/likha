import 'package:equatable/equatable.dart';

class GradeConfig extends Equatable {
  final String id;
  final String classId;
  final int termNumber;
  final double wwWeight;
  final double ptWeight;
  final double qaWeight;

  const GradeConfig({
    required this.id,
    required this.classId,
    required this.termNumber,
    required this.wwWeight,
    required this.ptWeight,
    required this.qaWeight,
  });

  @override
  List<Object?> get props => [
        id,
        classId,
        termNumber,
        wwWeight,
        ptWeight,
        qaWeight,
      ];
}
