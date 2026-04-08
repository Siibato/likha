import 'package:equatable/equatable.dart';

class TableOfSpecifications extends Equatable {
  final String id;
  final String classId;
  final int quarter;
  final String title;
  final String classificationMode;
  final int totalItems;
  final String timeUnit;
  final double easyPercentage;
  final double mediumPercentage;
  final double hardPercentage;
  final String createdAt;
  final String updatedAt;

  const TableOfSpecifications({
    required this.id,
    required this.classId,
    required this.quarter,
    required this.title,
    required this.classificationMode,
    required this.totalItems,
    this.timeUnit = 'days',
    this.easyPercentage = 50.0,
    this.mediumPercentage = 30.0,
    this.hardPercentage = 20.0,
    required this.createdAt,
    required this.updatedAt,
  });

  @override
  List<Object?> get props => [id, classId, quarter];
}

class TosCompetency extends Equatable {
  final String id;
  final String tosId;
  final String? competencyCode;
  final String competencyText;
  final int daysTaught;
  final int orderIndex;
  final int? easyCount;
  final int? mediumCount;
  final int? hardCount;
  final String createdAt;
  final String updatedAt;

  const TosCompetency({
    required this.id,
    required this.tosId,
    this.competencyCode,
    required this.competencyText,
    required this.daysTaught,
    required this.orderIndex,
    this.easyCount,
    this.mediumCount,
    this.hardCount,
    required this.createdAt,
    required this.updatedAt,
  });

  @override
  List<Object?> get props => [id, tosId];
}
