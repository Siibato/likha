import 'package:likha/core/database/db_schema.dart';
import 'package:likha/core/utils/transmutation_util.dart';

class PeriodGradeModel {
  final String id;
  final String classId;
  final String studentId;
  final int gradingPeriodNumber;
  final double? initialGrade;
  final int? transmutedGrade;
  final bool isLocked;
  final DateTime? computedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  const PeriodGradeModel({
    required this.id,
    required this.classId,
    required this.studentId,
    required this.gradingPeriodNumber,
    this.initialGrade,
    this.transmutedGrade,
    required this.isLocked,
    this.computedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  String get descriptor => TransmutationUtil.getDescriptor(transmutedGrade ?? 0);

  factory PeriodGradeModel.fromJson(Map<String, dynamic> json) {
    return PeriodGradeModel(
      id: json['id'] as String,
      classId: json['class_id'] as String,
      studentId: json['student_id'] as String,
      gradingPeriodNumber: json['grading_period_number'] as int,
      initialGrade: json['initial_grade'] != null ? (json['initial_grade'] as num).toDouble() : null,
      transmutedGrade: json['transmuted_grade'] != null ? (json['transmuted_grade'] as num).toInt() : null,
      isLocked: json['is_locked'] == true,
      computedAt: json['computed_at'] != null ? DateTime.parse(json['computed_at'] as String) : null,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse((json['updated_at'] ?? json['created_at']) as String),
    );
  }

  factory PeriodGradeModel.fromMap(Map<String, dynamic> map) {
    return PeriodGradeModel(
      id: map[CommonCols.id] as String,
      classId: map[PeriodGradesCols.classId] as String,
      studentId: map[PeriodGradesCols.studentId] as String,
      gradingPeriodNumber: map[PeriodGradesCols.gradingPeriodNumber] as int,
      initialGrade: map[PeriodGradesCols.initialGrade] != null ? (map[PeriodGradesCols.initialGrade] as num).toDouble() : null,
      transmutedGrade: map[PeriodGradesCols.transmutedGrade] != null ? (map[PeriodGradesCols.transmutedGrade] as num).toInt() : null,
      isLocked: map[PeriodGradesCols.isLocked] == 1,
      computedAt: map[PeriodGradesCols.computedAt] != null ? DateTime.parse(map[PeriodGradesCols.computedAt] as String) : null,
      createdAt: DateTime.parse(map[CommonCols.createdAt] as String),
      updatedAt: DateTime.parse(map[CommonCols.updatedAt] as String),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'class_id': classId,
    'student_id': studentId,
    'grading_period_number': gradingPeriodNumber,
    'initial_grade': initialGrade,
    'transmuted_grade': transmutedGrade,
    'is_locked': isLocked,
    'computed_at': computedAt?.toIso8601String(),
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
  };

  Map<String, dynamic> toMap() => {
    CommonCols.id: id,
    PeriodGradesCols.classId: classId,
    PeriodGradesCols.studentId: studentId,
    PeriodGradesCols.gradingPeriodNumber: gradingPeriodNumber,
    PeriodGradesCols.initialGrade: initialGrade,
    PeriodGradesCols.transmutedGrade: transmutedGrade,
    PeriodGradesCols.isLocked: isLocked ? 1 : 0,
    PeriodGradesCols.computedAt: computedAt?.toIso8601String(),
    CommonCols.createdAt: createdAt.toIso8601String(),
    CommonCols.updatedAt: updatedAt.toIso8601String(),
    CommonCols.cachedAt: DateTime.now().toIso8601String(),
    CommonCols.needsSync: 0,
  };
}
