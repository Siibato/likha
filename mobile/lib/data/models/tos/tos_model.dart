import 'package:likha/domain/tos/entities/tos_entity.dart';
import 'package:likha/core/database/db_schema.dart';

class TosModel extends TableOfSpecifications {
  const TosModel({
    required super.id,
    required super.classId,
    required super.gradingPeriodNumber,
    required super.title,
    required super.classificationMode,
    required super.totalItems,
    super.timeUnit = 'days',
    super.easyPercentage = 50.0,
    super.mediumPercentage = 30.0,
    super.hardPercentage = 20.0,
    super.rememberingPercentage = 16.67,
    super.understandingPercentage = 16.67,
    super.applyingPercentage = 16.67,
    super.analyzingPercentage = 16.67,
    super.evaluatingPercentage = 16.67,
    super.creatingPercentage = 16.67,
    required super.createdAt,
    required super.updatedAt,
  });

  factory TosModel.fromJson(Map<String, dynamic> json) {
    return TosModel(
      id: json['id'] as String,
      classId: json['class_id'] as String,
      gradingPeriodNumber: json['grading_period_number'] as int? ?? json['quarter'] as int,
      title: json['title'] as String,
      classificationMode: json['classification_mode'] as String,
      totalItems: json['total_items'] as int,
      timeUnit: json['time_unit'] as String? ?? 'days',
      easyPercentage: (json['easy_percentage'] as num?)?.toDouble() ?? 50.0,
      mediumPercentage: (json['medium_percentage'] as num?)?.toDouble() ?? 30.0,
      hardPercentage: (json['hard_percentage'] as num?)?.toDouble() ?? 20.0,
      rememberingPercentage: (json['remembering_percentage'] as num?)?.toDouble() ?? 16.67,
      understandingPercentage: (json['understanding_percentage'] as num?)?.toDouble() ?? 16.67,
      applyingPercentage: (json['applying_percentage'] as num?)?.toDouble() ?? 16.67,
      analyzingPercentage: (json['analyzing_percentage'] as num?)?.toDouble() ?? 16.67,
      evaluatingPercentage: (json['evaluating_percentage'] as num?)?.toDouble() ?? 16.67,
      creatingPercentage: (json['creating_percentage'] as num?)?.toDouble() ?? 16.67,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  factory TosModel.fromMap(Map<String, dynamic> map) {
    return TosModel(
      id: map[CommonCols.id] as String,
      classId: map[TosCols.classId] as String,
      gradingPeriodNumber: map[TosCols.gradingPeriodNumber] as int,
      title: map[TosCols.title] as String,
      classificationMode: map[TosCols.classificationMode] as String,
      totalItems: map[TosCols.totalItems] as int,
      timeUnit: map[TosCols.timeUnit] as String? ?? 'days',
      easyPercentage: (map[TosCols.easyPercentage] as num?)?.toDouble() ?? 50.0,
      mediumPercentage: (map[TosCols.mediumPercentage] as num?)?.toDouble() ?? 30.0,
      hardPercentage: (map[TosCols.hardPercentage] as num?)?.toDouble() ?? 20.0,
      rememberingPercentage: (map[TosCols.rememberingPercentage] as num?)?.toDouble() ?? 16.67,
      understandingPercentage: (map[TosCols.understandingPercentage] as num?)?.toDouble() ?? 16.67,
      applyingPercentage: (map[TosCols.applyingPercentage] as num?)?.toDouble() ?? 16.67,
      analyzingPercentage: (map[TosCols.analyzingPercentage] as num?)?.toDouble() ?? 16.67,
      evaluatingPercentage: (map[TosCols.evaluatingPercentage] as num?)?.toDouble() ?? 16.67,
      creatingPercentage: (map[TosCols.creatingPercentage] as num?)?.toDouble() ?? 16.67,
      createdAt: DateTime.parse(map[CommonCols.createdAt] as String),
      updatedAt: DateTime.parse(map[CommonCols.updatedAt] as String),
    );
  }

  Map<String, dynamic> toMap() => {
    CommonCols.id: id,
    TosCols.classId: classId,
    TosCols.gradingPeriodNumber: gradingPeriodNumber,
    TosCols.title: title,
    TosCols.classificationMode: classificationMode,
    TosCols.totalItems: totalItems,
    TosCols.timeUnit: timeUnit,
    TosCols.easyPercentage: easyPercentage,
    TosCols.mediumPercentage: mediumPercentage,
    TosCols.hardPercentage: hardPercentage,
    TosCols.rememberingPercentage: rememberingPercentage,
    TosCols.understandingPercentage: understandingPercentage,
    TosCols.applyingPercentage: applyingPercentage,
    TosCols.analyzingPercentage: analyzingPercentage,
    TosCols.evaluatingPercentage: evaluatingPercentage,
    TosCols.creatingPercentage: creatingPercentage,
    CommonCols.createdAt: createdAt.toIso8601String(),
    CommonCols.updatedAt: updatedAt.toIso8601String(),
    CommonCols.cachedAt: DateTime.now().toIso8601String(),
    CommonCols.needsSync: 0,
  };

  Map<String, dynamic> toJson() => {
    'id': id,
    'class_id': classId,
    'grading_period_number': gradingPeriodNumber,
    'title': title,
    'classification_mode': classificationMode,
    'total_items': totalItems,
    'time_unit': timeUnit,
    'easy_percentage': easyPercentage,
    'medium_percentage': mediumPercentage,
    'hard_percentage': hardPercentage,
    'remembering_percentage': rememberingPercentage,
    'understanding_percentage': understandingPercentage,
    'applying_percentage': applyingPercentage,
    'analyzing_percentage': analyzingPercentage,
    'evaluating_percentage': evaluatingPercentage,
    'creating_percentage': creatingPercentage,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
  };
}

class CompetencyModel extends TosCompetency {
  const CompetencyModel({
    required super.id,
    required super.tosId,
    super.competencyCode,
    required super.competencyText,
    required super.timeUnitsTaught,
    required super.orderIndex,
    super.easyCount,
    super.mediumCount,
    super.hardCount,
    super.rememberingCount,
    super.understandingCount,
    super.applyingCount,
    super.analyzingCount,
    super.evaluatingCount,
    super.creatingCount,
    required super.createdAt,
    required super.updatedAt,
  });

  factory CompetencyModel.fromJson(Map<String, dynamic> json) {
    return CompetencyModel(
      id: json['id'] as String,
      tosId: json['tos_id'] as String? ?? '',
      competencyCode: json['competency_code'] as String?,
      competencyText: json['competency_text'] as String,
      timeUnitsTaught: json['time_units_taught'] as int? ?? json['days_taught'] as int,
      orderIndex: json['order_index'] as int? ?? 0,
      easyCount: json['easy_count'] as int?,
      mediumCount: json['medium_count'] as int?,
      hardCount: json['hard_count'] as int?,
      rememberingCount: json['remembering_count'] as int?,
      understandingCount: json['understanding_count'] as int?,
      applyingCount: json['applying_count'] as int?,
      analyzingCount: json['analyzing_count'] as int?,
      evaluatingCount: json['evaluating_count'] as int?,
      creatingCount: json['creating_count'] as int?,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at'] as String) : DateTime.now(),
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at'] as String) : DateTime.now(),
    );
  }

  factory CompetencyModel.fromMap(Map<String, dynamic> map) {
    return CompetencyModel(
      id: map[CommonCols.id] as String,
      tosId: map[TosCompetenciesCols.tosId] as String,
      competencyCode: map[TosCompetenciesCols.competencyCode] as String?,
      competencyText: map[TosCompetenciesCols.competencyText] as String,
      timeUnitsTaught: map[TosCompetenciesCols.timeUnitsTaught] as int,
      orderIndex: map[TosCompetenciesCols.orderIndex] as int,
      easyCount: map[TosCompetenciesCols.easyCount] as int?,
      mediumCount: map[TosCompetenciesCols.mediumCount] as int?,
      hardCount: map[TosCompetenciesCols.hardCount] as int?,
      rememberingCount: map[TosCompetenciesCols.rememberingCount] as int?,
      understandingCount: map[TosCompetenciesCols.understandingCount] as int?,
      applyingCount: map[TosCompetenciesCols.applyingCount] as int?,
      analyzingCount: map[TosCompetenciesCols.analyzingCount] as int?,
      evaluatingCount: map[TosCompetenciesCols.evaluatingCount] as int?,
      creatingCount: map[TosCompetenciesCols.creatingCount] as int?,
      createdAt: DateTime.parse(map[CommonCols.createdAt] as String),
      updatedAt: DateTime.parse(map[CommonCols.updatedAt] as String),
    );
  }

  Map<String, dynamic> toMap() => {
    CommonCols.id: id,
    TosCompetenciesCols.tosId: tosId,
    TosCompetenciesCols.competencyCode: competencyCode,
    TosCompetenciesCols.competencyText: competencyText,
    TosCompetenciesCols.timeUnitsTaught: timeUnitsTaught,
    TosCompetenciesCols.orderIndex: orderIndex,
    TosCompetenciesCols.easyCount: easyCount,
    TosCompetenciesCols.mediumCount: mediumCount,
    TosCompetenciesCols.hardCount: hardCount,
    TosCompetenciesCols.rememberingCount: rememberingCount,
    TosCompetenciesCols.understandingCount: understandingCount,
    TosCompetenciesCols.applyingCount: applyingCount,
    TosCompetenciesCols.analyzingCount: analyzingCount,
    TosCompetenciesCols.evaluatingCount: evaluatingCount,
    TosCompetenciesCols.creatingCount: creatingCount,
    CommonCols.createdAt: createdAt.toIso8601String(),
    CommonCols.updatedAt: updatedAt.toIso8601String(),
    CommonCols.cachedAt: DateTime.now().toIso8601String(),
    CommonCols.needsSync: 0,
  };

  Map<String, dynamic> toJson() => {
    'id': id,
    'tos_id': tosId,
    'competency_code': competencyCode,
    'competency_text': competencyText,
    'time_units_taught': timeUnitsTaught,
    'order_index': orderIndex,
    'easy_count': easyCount,
    'medium_count': mediumCount,
    'hard_count': hardCount,
    'remembering_count': rememberingCount,
    'understanding_count': understandingCount,
    'applying_count': applyingCount,
    'analyzing_count': analyzingCount,
    'evaluating_count': evaluatingCount,
    'creating_count': creatingCount,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
  };
}
