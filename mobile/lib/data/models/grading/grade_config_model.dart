import 'package:likha/core/database/db_schema.dart';

class GradeConfigModel {
  final String id;
  final String classId;
  final int quarter;
  final double wwWeight;
  final double ptWeight;
  final double qaWeight;
  final String createdAt;
  final String updatedAt;

  const GradeConfigModel({
    required this.id,
    required this.classId,
    required this.quarter,
    required this.wwWeight,
    required this.ptWeight,
    required this.qaWeight,
    required this.createdAt,
    required this.updatedAt,
  });

  factory GradeConfigModel.fromJson(Map<String, dynamic> json) {
    return GradeConfigModel(
      id: json['id'] as String,
      classId: json['class_id'] as String,
      quarter: (json['quarter'] as num).toInt(),
      wwWeight: (json['ww_weight'] as num).toDouble(),
      ptWeight: (json['pt_weight'] as num).toDouble(),
      qaWeight: (json['qa_weight'] as num).toDouble(),
      createdAt: json['created_at'] as String,
      updatedAt: (json['updated_at'] ?? json['created_at']) as String,
    );
  }

  factory GradeConfigModel.fromMap(Map<String, dynamic> map) {
    return GradeConfigModel(
      id: map[CommonCols.id] as String,
      classId: map[GradeComponentsConfigCols.classId] as String,
      quarter: map[GradeComponentsConfigCols.quarter] as int,
      wwWeight: (map[GradeComponentsConfigCols.wwWeight] as num).toDouble(),
      ptWeight: (map[GradeComponentsConfigCols.ptWeight] as num).toDouble(),
      qaWeight: (map[GradeComponentsConfigCols.qaWeight] as num).toDouble(),
      createdAt: map[CommonCols.createdAt] as String,
      updatedAt: map[CommonCols.updatedAt] as String,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'class_id': classId,
    'quarter': quarter,
    'ww_weight': wwWeight,
    'pt_weight': ptWeight,
    'qa_weight': qaWeight,
    'created_at': createdAt,
    'updated_at': updatedAt,
  };

  Map<String, dynamic> toMap() => {
    CommonCols.id: id,
    GradeComponentsConfigCols.classId: classId,
    GradeComponentsConfigCols.quarter: quarter,
    GradeComponentsConfigCols.wwWeight: wwWeight,
    GradeComponentsConfigCols.ptWeight: ptWeight,
    GradeComponentsConfigCols.qaWeight: qaWeight,
    CommonCols.createdAt: createdAt,
    CommonCols.updatedAt: updatedAt,
    CommonCols.cachedAt: DateTime.now().toIso8601String(),
    CommonCols.needsSync: 0,
  };
}
