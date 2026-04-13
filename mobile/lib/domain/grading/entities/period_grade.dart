import 'package:equatable/equatable.dart';
import 'package:likha/core/utils/transmutation_util.dart';

class PeriodGrade extends Equatable {
  final String id;
  final String classId;
  final String studentId;
  final int gradingPeriodNumber;
  final double? initialGrade;
  final int? transmutedGrade;
  final bool isLocked;
  final String? computedAt;
  final bool isPreview;

  const PeriodGrade({
    required this.id,
    required this.classId,
    required this.studentId,
    required this.gradingPeriodNumber,
    this.initialGrade,
    this.transmutedGrade,
    required this.isLocked,
    this.computedAt,
    this.isPreview = false,
  });

  String get descriptor =>
      TransmutationUtil.getDescriptor(transmutedGrade ?? 0);

  @override
  List<Object?> get props => [
        id,
        classId,
        studentId,
        gradingPeriodNumber,
        initialGrade,
        transmutedGrade,
        isLocked,
        computedAt,
        isPreview,
      ];
}
