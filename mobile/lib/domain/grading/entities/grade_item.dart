import 'package:equatable/equatable.dart';

class GradeItem extends Equatable {
  final String id;
  final String classId;
  final String title;
  final String component;
  final int gradingPeriodNumber;
  final double totalPoints;
  final String sourceType;
  final String? sourceId;
  final int orderIndex;
  final DateTime createdAt;
  final DateTime updatedAt;

  const GradeItem({
    required this.id,
    required this.classId,
    required this.title,
    required this.component,
    required this.gradingPeriodNumber,
    required this.totalPoints,
    required this.sourceType,
    this.sourceId,
    required this.orderIndex,
    required this.createdAt,
    required this.updatedAt,
  });

  @override
  List<Object?> get props => [
        id,
        classId,
        title,
        component,
        gradingPeriodNumber,
        totalPoints,
        sourceType,
        sourceId,
        orderIndex,
        createdAt,
        updatedAt,
      ];

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'class_id': classId,
      'title': title,
      'component': component,
      'grading_period_number': gradingPeriodNumber,
      'total_points': totalPoints,
      'source_type': sourceType,
      'source_id': sourceId,
      'order_index': orderIndex,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
