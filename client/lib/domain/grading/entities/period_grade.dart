import 'package:equatable/equatable.dart';
import 'package:likha/core/utils/transmutation_util.dart';

class PeriodGrade extends Equatable {
  final String id;
  final String classId;
  final String studentId;
  final int termNumber;
  final double? initialGrade;
  final int? transmutedGrade;
  final bool isLocked;
  final bool isPreview;

  const PeriodGrade({
    required this.id,
    required this.classId,
    required this.studentId,
    required this.termNumber,
    this.initialGrade,
    this.transmutedGrade,
    required this.isLocked,
    this.isPreview = false,
  });

  String get descriptor =>
      TransmutationUtil.getDescriptor(transmutedGrade ?? 0);

  @override
  List<Object?> get props => [
        id,
        classId,
        studentId,
        termNumber,
        initialGrade,
        transmutedGrade,
        isLocked,
        isPreview,
      ];
}
