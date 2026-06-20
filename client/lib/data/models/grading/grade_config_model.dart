import 'package:likha/core/database/db_schema.dart';
import 'package:likha/core/logging/provider_logger.dart';

class GradeConfigModel {
  final String id;
  final String classId;
  final int termNumber;
  final double wwWeight;
  final double ptWeight;
  final double qaWeight;
  final String createdAt;
  final String updatedAt;

  const GradeConfigModel({
    required this.id,
    required this.classId,
    required this.termNumber,
    required this.wwWeight,
    required this.ptWeight,
    required this.qaWeight,
    required this.createdAt,
    required this.updatedAt,
  });

  factory GradeConfigModel.fromJson(Map<String, dynamic> json) {
    ProviderLogger.instance.debug('GradeConfigModel.fromJson() called with: $json');
    try {
      final now = DateTime.now().toIso8601String();
      final model = GradeConfigModel(
        id: json['id'] as String,
        classId: json['class_id'] as String,
        termNumber: json['term_number'] as int,
        wwWeight: (json['ww_weight'] as num).toDouble(),
        ptWeight: (json['pt_weight'] as num).toDouble(),
        qaWeight: (json['qa_weight'] as num).toDouble(),
        createdAt: json['created_at'] as String? ?? now,
        updatedAt: json['updated_at'] as String? ?? now,
      );
      ProviderLogger.instance.debug('GradeConfigModel created successfully: ${model.id}');
      return model;
    } catch (e) {
      ProviderLogger.instance.debug('GradeConfigModel.fromJson() failed: $e');
      rethrow;
    }
  }

  factory GradeConfigModel.fromMap(Map<String, dynamic> map) {
    return GradeConfigModel(
      id: map[CommonCols.id] as String,
      classId: map[GradeRecordCols.classId] as String,
      termNumber: map[GradeRecordCols.termNumber] as int,
      wwWeight: (map[GradeRecordCols.wwWeight] as num).toDouble(),
      ptWeight: (map[GradeRecordCols.ptWeight] as num).toDouble(),
      qaWeight: (map[GradeRecordCols.qaWeight] as num).toDouble(),
      createdAt: map[CommonCols.createdAt] as String,
      updatedAt: map[CommonCols.updatedAt] as String,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'class_id': classId,
    'term_number': termNumber,
    'ww_weight': wwWeight,
    'pt_weight': ptWeight,
    'qa_weight': qaWeight,
    'created_at': createdAt,
    'updated_at': updatedAt,
  };

  Map<String, dynamic> toMap() => {
    CommonCols.id: id,
    GradeRecordCols.classId: classId,
    GradeRecordCols.termNumber: termNumber,
    GradeRecordCols.wwWeight: wwWeight,
    GradeRecordCols.ptWeight: ptWeight,
    GradeRecordCols.qaWeight: qaWeight,
    CommonCols.createdAt: createdAt,
    CommonCols.updatedAt: updatedAt,
    CommonCols.cachedAt: DateTime.now().toIso8601String(),
    CommonCols.syncStatus: 'synced',
  };
}
