import 'package:equatable/equatable.dart';

class TableOfSpecifications extends Equatable {
  final String id;
  final String classId;
  final int gradingPeriodNumber;
  final String title;
  final String classificationMode;
  final int totalItems;
  final String timeUnit;
  final double easyPercentage;
  final double mediumPercentage;
  final double hardPercentage;
  final double rememberingPercentage;
  final double understandingPercentage;
  final double applyingPercentage;
  final double analyzingPercentage;
  final double evaluatingPercentage;
  final double creatingPercentage;
  final String createdAt;
  final String updatedAt;

  const TableOfSpecifications({
    required this.id,
    required this.classId,
    required this.gradingPeriodNumber,
    required this.title,
    required this.classificationMode,
    required this.totalItems,
    this.timeUnit = 'days',
    this.easyPercentage = 50.0,
    this.mediumPercentage = 30.0,
    this.hardPercentage = 20.0,
    this.rememberingPercentage = 16.67,
    this.understandingPercentage = 16.67,
    this.applyingPercentage = 16.67,
    this.analyzingPercentage = 16.67,
    this.evaluatingPercentage = 16.67,
    this.creatingPercentage = 16.67,
    required this.createdAt,
    required this.updatedAt,
  });

  @override
  List<Object?> get props => [id, classId, gradingPeriodNumber];
}

class TosCompetency extends Equatable {
  final String id;
  final String tosId;
  final String? competencyCode;
  final String competencyText;
  final int timeUnitsTaught;
  final int orderIndex;
  final int? easyCount;
  final int? mediumCount;
  final int? hardCount;
  final int? rememberingCount;
  final int? understandingCount;
  final int? applyingCount;
  final int? analyzingCount;
  final int? evaluatingCount;
  final int? creatingCount;
  final String createdAt;
  final String updatedAt;

  const TosCompetency({
    required this.id,
    required this.tosId,
    this.competencyCode,
    required this.competencyText,
    required this.timeUnitsTaught,
    required this.orderIndex,
    this.easyCount,
    this.mediumCount,
    this.hardCount,
    this.rememberingCount,
    this.understandingCount,
    this.applyingCount,
    this.analyzingCount,
    this.evaluatingCount,
    this.creatingCount,
    required this.createdAt,
    required this.updatedAt,
  });

  @override
  List<Object?> get props => [id, tosId];
}
