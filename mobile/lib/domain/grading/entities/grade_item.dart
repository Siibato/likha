import 'package:equatable/equatable.dart';

class GradeItem extends Equatable {
  final String id;
  final String classId;
  final String title;
  final String component;
  final int quarter;
  final double totalPoints;
  final bool isDepartmentalExam;
  final String sourceType;
  final String? sourceId;
  final int orderIndex;

  const GradeItem({
    required this.id,
    required this.classId,
    required this.title,
    required this.component,
    required this.quarter,
    required this.totalPoints,
    required this.isDepartmentalExam,
    required this.sourceType,
    this.sourceId,
    required this.orderIndex,
  });

  @override
  List<Object?> get props => [
        id,
        classId,
        title,
        component,
        quarter,
        totalPoints,
        isDepartmentalExam,
        sourceType,
        sourceId,
        orderIndex,
      ];
}
