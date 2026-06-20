import 'package:equatable/equatable.dart';

class GradeScore extends Equatable {
  final String id;
  final String gradeItemId;
  final String studentId;
  final double? score;
  final bool isAutoPopulated;
  final double? overrideScore;
  final String syncStatus;

  const GradeScore({
    required this.id,
    required this.gradeItemId,
    required this.studentId,
    this.score,
    required this.isAutoPopulated,
    this.overrideScore,
    this.syncStatus = 'synced',
  });

  double? get effectiveScore => overrideScore ?? score;

  @override
  List<Object?> get props => [
        id,
        gradeItemId,
        studentId,
        score,
        isAutoPopulated,
        overrideScore,
        syncStatus,
      ];
}
