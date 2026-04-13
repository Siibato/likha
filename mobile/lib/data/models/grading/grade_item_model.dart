import 'package:likha/core/database/db_schema.dart';

class GradeItemModel {
  final String id;
  final String classId;
  final String title;
  final String component;
  final int gradingPeriodNumber;
  final double totalPoints;
  final String sourceType;
  final String? sourceId;
  final int orderIndex;
  final String createdAt;
  final String updatedAt;

  const GradeItemModel({
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

  factory GradeItemModel.fromJson(Map<String, dynamic> json) {
    return GradeItemModel(
      id: json['id'] as String,
      classId: json['class_id'] as String,
      title: json['title'] as String,
      component: json['component'] as String,
      gradingPeriodNumber: (json['grading_period_number'] as num?)?.toInt() ?? (json['quarter'] as num).toInt(),
      totalPoints: (json['total_points'] as num).toDouble(),
      sourceType: (json['source_type'] as String?) ?? 'manual',
      sourceId: json['source_id'] as String?,
      orderIndex: (json['order_index'] as num?)?.toInt() ?? 0,
      createdAt: json['created_at'] as String,
      updatedAt: (json['updated_at'] ?? json['created_at']) as String,
    );
  }

  factory GradeItemModel.fromMap(Map<String, dynamic> map) {
    return GradeItemModel(
      id: map[CommonCols.id] as String,
      classId: map[GradeItemsCols.classId] as String,
      title: map[GradeItemsCols.title] as String,
      component: map[GradeItemsCols.component] as String,
      gradingPeriodNumber: map[GradeItemsCols.gradingPeriodNumber] as int,
      totalPoints: (map[GradeItemsCols.totalPoints] as num).toDouble(),
      sourceType: map[GradeItemsCols.sourceType] as String,
      sourceId: map[GradeItemsCols.sourceId] as String?,
      orderIndex: (map[GradeItemsCols.orderIndex] as num?)?.toInt() ?? 0,
      createdAt: map[CommonCols.createdAt] as String,
      updatedAt: map[CommonCols.updatedAt] as String,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'class_id': classId,
    'title': title,
    'component': component,
    'grading_period_number': gradingPeriodNumber,
    'total_points': totalPoints,
    'source_type': sourceType,
    'source_id': sourceId,
    'order_index': orderIndex,
    'created_at': createdAt,
    'updated_at': updatedAt,
  };

  Map<String, dynamic> toMap() => {
    CommonCols.id: id,
    GradeItemsCols.classId: classId,
    GradeItemsCols.title: title,
    GradeItemsCols.component: component,
    GradeItemsCols.gradingPeriodNumber: gradingPeriodNumber,
    GradeItemsCols.totalPoints: totalPoints,
    GradeItemsCols.sourceType: sourceType,
    GradeItemsCols.sourceId: sourceId,
    GradeItemsCols.orderIndex: orderIndex,
    CommonCols.createdAt: createdAt,
    CommonCols.updatedAt: updatedAt,
    CommonCols.cachedAt: DateTime.now().toIso8601String(),
    CommonCols.needsSync: 0,
  };
}
