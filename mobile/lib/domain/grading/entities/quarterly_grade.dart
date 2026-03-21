import 'package:equatable/equatable.dart';
import 'package:likha/core/utils/transmutation_util.dart';

class QuarterlyGrade extends Equatable {
  final String id;
  final String classId;
  final String studentId;
  final int quarter;
  final double? wwPercentage;
  final double? ptPercentage;
  final double? qaPercentage;
  final double? wwWeighted;
  final double? ptWeighted;
  final double? qaWeighted;
  final double? initialGrade;
  final int? transmutedGrade;
  final bool isComplete;
  final String? computedAt;
  final bool isPreview;

  const QuarterlyGrade({
    required this.id,
    required this.classId,
    required this.studentId,
    required this.quarter,
    this.wwPercentage,
    this.ptPercentage,
    this.qaPercentage,
    this.wwWeighted,
    this.ptWeighted,
    this.qaWeighted,
    this.initialGrade,
    this.transmutedGrade,
    required this.isComplete,
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
        quarter,
        wwPercentage,
        ptPercentage,
        qaPercentage,
        wwWeighted,
        ptWeighted,
        qaWeighted,
        initialGrade,
        transmutedGrade,
        isComplete,
        computedAt,
        isPreview,
      ];
}
