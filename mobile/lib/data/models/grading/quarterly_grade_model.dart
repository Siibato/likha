import 'package:likha/core/database/db_schema.dart';
import 'package:likha/core/utils/transmutation_util.dart';

class QuarterlyGradeModel {
  final String id;
  final String classId;
  final String studentId;
  final int quarter;
  final double? wwPercentage;
  final double? ptPercentage;
  final double? qaPercentage;
  final double? wwWeighted;
  final double? ptWeighted;
  final double? qaWeighted;
  final double? initialGrade;
  final int? transmutedGrade;
  final bool isComplete;
  final String? computedAt;
  final String createdAt;
  final String updatedAt;

  const QuarterlyGradeModel({
    required this.id,
    required this.classId,
    required this.studentId,
    required this.quarter,
    this.wwPercentage,
    this.ptPercentage,
    this.qaPercentage,
    this.wwWeighted,
    this.ptWeighted,
    this.qaWeighted,
    this.initialGrade,
    this.transmutedGrade,
    required this.isComplete,
    this.computedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  String get descriptor => TransmutationUtil.getDescriptor(transmutedGrade ?? 0);

  factory QuarterlyGradeModel.fromJson(Map<String, dynamic> json) {
    return QuarterlyGradeModel(
      id: json['id'] as String,
      classId: json['class_id'] as String,
      studentId: json['student_id'] as String,
      quarter: (json['quarter'] as num).toInt(),
      wwPercentage: json['ww_percentage'] != null ? (json['ww_percentage'] as num).toDouble() : null,
      ptPercentage: json['pt_percentage'] != null ? (json['pt_percentage'] as num).toDouble() : null,
      qaPercentage: json['qa_percentage'] != null ? (json['qa_percentage'] as num).toDouble() : null,
      wwWeighted: json['ww_weighted'] != null ? (json['ww_weighted'] as num).toDouble() : null,
      ptWeighted: json['pt_weighted'] != null ? (json['pt_weighted'] as num).toDouble() : null,
      qaWeighted: json['qa_weighted'] != null ? (json['qa_weighted'] as num).toDouble() : null,
      initialGrade: json['initial_grade'] != null ? (json['initial_grade'] as num).toDouble() : null,
      transmutedGrade: json['transmuted_grade'] != null ? (json['transmuted_grade'] as num).toInt() : null,
      isComplete: json['is_complete'] == true,
      computedAt: json['computed_at'] as String?,
      createdAt: json['created_at'] as String,
      updatedAt: (json['updated_at'] ?? json['created_at']) as String,
    );
  }

  factory QuarterlyGradeModel.fromMap(Map<String, dynamic> map) {
    return QuarterlyGradeModel(
      id: map[CommonCols.id] as String,
      classId: map[QuarterlyGradesCols.classId] as String,
      studentId: map[QuarterlyGradesCols.studentId] as String,
      quarter: map[QuarterlyGradesCols.quarter] as int,
      wwPercentage: map[QuarterlyGradesCols.wwPercentage] != null ? (map[QuarterlyGradesCols.wwPercentage] as num).toDouble() : null,
      ptPercentage: map[QuarterlyGradesCols.ptPercentage] != null ? (map[QuarterlyGradesCols.ptPercentage] as num).toDouble() : null,
      qaPercentage: map[QuarterlyGradesCols.qaPercentage] != null ? (map[QuarterlyGradesCols.qaPercentage] as num).toDouble() : null,
      wwWeighted: map[QuarterlyGradesCols.wwWeighted] != null ? (map[QuarterlyGradesCols.wwWeighted] as num).toDouble() : null,
      ptWeighted: map[QuarterlyGradesCols.ptWeighted] != null ? (map[QuarterlyGradesCols.ptWeighted] as num).toDouble() : null,
      qaWeighted: map[QuarterlyGradesCols.qaWeighted] != null ? (map[QuarterlyGradesCols.qaWeighted] as num).toDouble() : null,
      initialGrade: map[QuarterlyGradesCols.initialGrade] != null ? (map[QuarterlyGradesCols.initialGrade] as num).toDouble() : null,
      transmutedGrade: map[QuarterlyGradesCols.transmutedGrade] != null ? (map[QuarterlyGradesCols.transmutedGrade] as num).toInt() : null,
      isComplete: map[QuarterlyGradesCols.isComplete] == 1,
      computedAt: map[QuarterlyGradesCols.computedAt] as String?,
      createdAt: map[CommonCols.createdAt] as String,
      updatedAt: map[CommonCols.updatedAt] as String,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'class_id': classId,
    'student_id': studentId,
    'quarter': quarter,
    'ww_percentage': wwPercentage,
    'pt_percentage': ptPercentage,
    'qa_percentage': qaPercentage,
    'ww_weighted': wwWeighted,
    'pt_weighted': ptWeighted,
    'qa_weighted': qaWeighted,
    'initial_grade': initialGrade,
    'transmuted_grade': transmutedGrade,
    'is_complete': isComplete,
    'computed_at': computedAt,
    'created_at': createdAt,
    'updated_at': updatedAt,
  };

  Map<String, dynamic> toMap() => {
    CommonCols.id: id,
    QuarterlyGradesCols.classId: classId,
    QuarterlyGradesCols.studentId: studentId,
    QuarterlyGradesCols.quarter: quarter,
    QuarterlyGradesCols.wwPercentage: wwPercentage,
    QuarterlyGradesCols.ptPercentage: ptPercentage,
    QuarterlyGradesCols.qaPercentage: qaPercentage,
    QuarterlyGradesCols.wwWeighted: wwWeighted,
    QuarterlyGradesCols.ptWeighted: ptWeighted,
    QuarterlyGradesCols.qaWeighted: qaWeighted,
    QuarterlyGradesCols.initialGrade: initialGrade,
    QuarterlyGradesCols.transmutedGrade: transmutedGrade,
    QuarterlyGradesCols.isComplete: isComplete ? 1 : 0,
    QuarterlyGradesCols.computedAt: computedAt,
    CommonCols.createdAt: createdAt,
    CommonCols.updatedAt: updatedAt,
    CommonCols.cachedAt: DateTime.now().toIso8601String(),
    CommonCols.needsSync: 0,
  };
}
