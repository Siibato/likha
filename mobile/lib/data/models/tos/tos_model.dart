import 'package:likha/domain/tos/entities/tos_entity.dart';
import 'package:likha/core/database/db_schema.dart';

class TosModel extends TableOfSpecifications {
  const TosModel({
    required super.id,
    required super.classId,
    required super.quarter,
    required super.title,
    required super.classificationMode,
    required super.totalItems,
    required super.createdAt,
    required super.updatedAt,
  });

  factory TosModel.fromJson(Map<String, dynamic> json) {
    return TosModel(
      id: json['id'] as String,
      classId: json['class_id'] as String,
      quarter: json['quarter'] as int,
      title: json['title'] as String,
      classificationMode: json['classification_mode'] as String,
      totalItems: json['total_items'] as int,
      createdAt: json['created_at'] as String,
      updatedAt: json['updated_at'] as String,
    );
  }

  factory TosModel.fromMap(Map<String, dynamic> map) {
    return TosModel(
      id: map[CommonCols.id] as String,
      classId: map[TosCols.classId] as String,
      quarter: map[TosCols.quarter] as int,
      title: map[TosCols.title] as String,
      classificationMode: map[TosCols.classificationMode] as String,
      totalItems: map[TosCols.totalItems] as int,
      createdAt: map[CommonCols.createdAt] as String,
      updatedAt: map[CommonCols.updatedAt] as String,
    );
  }

  Map<String, dynamic> toMap() => {
    CommonCols.id: id,
    TosCols.classId: classId,
    TosCols.quarter: quarter,
    TosCols.title: title,
    TosCols.classificationMode: classificationMode,
    TosCols.totalItems: totalItems,
    CommonCols.createdAt: createdAt,
    CommonCols.updatedAt: updatedAt,
    CommonCols.cachedAt: DateTime.now().toIso8601String(),
    CommonCols.needsSync: 0,
  };
}

class CompetencyModel extends TosCompetency {
  const CompetencyModel({
    required super.id,
    required super.tosId,
    super.competencyCode,
    required super.competencyText,
    required super.daysTaught,
    required super.orderIndex,
    required super.createdAt,
    required super.updatedAt,
  });

  factory CompetencyModel.fromJson(Map<String, dynamic> json) {
    return CompetencyModel(
      id: json['id'] as String,
      tosId: json['tos_id'] as String? ?? '',
      competencyCode: json['competency_code'] as String?,
      competencyText: json['competency_text'] as String,
      daysTaught: json['days_taught'] as int,
      orderIndex: json['order_index'] as int? ?? 0,
      createdAt: json['created_at'] as String? ?? '',
      updatedAt: json['updated_at'] as String? ?? '',
    );
  }

  factory CompetencyModel.fromMap(Map<String, dynamic> map) {
    return CompetencyModel(
      id: map[CommonCols.id] as String,
      tosId: map[TosCompetenciesCols.tosId] as String,
      competencyCode: map[TosCompetenciesCols.competencyCode] as String?,
      competencyText: map[TosCompetenciesCols.competencyText] as String,
      daysTaught: map[TosCompetenciesCols.daysTaught] as int,
      orderIndex: map[TosCompetenciesCols.orderIndex] as int,
      createdAt: map[CommonCols.createdAt] as String,
      updatedAt: map[CommonCols.updatedAt] as String,
    );
  }

  Map<String, dynamic> toMap() => {
    CommonCols.id: id,
    TosCompetenciesCols.tosId: tosId,
    TosCompetenciesCols.competencyCode: competencyCode,
    TosCompetenciesCols.competencyText: competencyText,
    TosCompetenciesCols.daysTaught: daysTaught,
    TosCompetenciesCols.orderIndex: orderIndex,
    CommonCols.createdAt: createdAt,
    CommonCols.updatedAt: updatedAt,
    CommonCols.cachedAt: DateTime.now().toIso8601String(),
    CommonCols.needsSync: 0,
  };

  Map<String, dynamic> toJson() => {
    'id': id,
    'tos_id': tosId,
    'competency_code': competencyCode,
    'competency_text': competencyText,
    'days_taught': daysTaught,
    'order_index': orderIndex,
  };
}
