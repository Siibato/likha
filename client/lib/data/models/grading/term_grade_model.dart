import 'package:likha/core/database/db_schema.dart';
import 'package:likha/core/utils/transmutation_util.dart';

class TermGradeModel {
  final String id;
  final String classId;
  final String studentId;
  final int termNumber;
  final double? initialGrade;
  final int? transmutedGrade;
  final bool isLocked;
  final DateTime createdAt;
  final DateTime updatedAt;

  const TermGradeModel({
    required this.id,
    required this.classId,
    required this.studentId,
    required this.termNumber,
    this.initialGrade,
    this.transmutedGrade,
    required this.isLocked,
    required this.createdAt,
    required this.updatedAt,
  });

  String get descriptor => TransmutationUtil.getDescriptor(transmutedGrade ?? 0);

  factory TermGradeModel.fromJson(Map<String, dynamic> json) {
    return TermGradeModel(
      id: json['id'] as String,
      classId: json['class_id'] as String,
      studentId: json['student_id'] as String,
      termNumber: json['term_number'] as int,
      initialGrade: json['initial_grade'] != null ? (json['initial_grade'] as num).toDouble() : null,
      transmutedGrade: json['transmuted_grade'] != null ? (json['transmuted_grade'] as num).toInt() : null,
      isLocked: json['is_locked'] == true,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse((json['updated_at'] ?? json['created_at']) as String),
    );
  }

  factory TermGradeModel.fromMap(Map<String, dynamic> map) {
    return TermGradeModel(
      id: map[CommonCols.id] as String,
      classId: map[TermGradesCols.classId] as String,
      studentId: map[TermGradesCols.studentId] as String,
      termNumber: map[TermGradesCols.termNumber] as int,
      initialGrade: map[TermGradesCols.initialGrade] != null ? (map[TermGradesCols.initialGrade] as num).toDouble() : null,
      transmutedGrade: map[TermGradesCols.transmutedGrade] != null ? (map[TermGradesCols.transmutedGrade] as num).toInt() : null,
      isLocked: map[TermGradesCols.isLocked] == 1,
      createdAt: DateTime.parse(map[CommonCols.createdAt] as String),
      updatedAt: DateTime.parse(map[CommonCols.updatedAt] as String),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'class_id': classId,
    'student_id': studentId,
    'term_number': termNumber,
    'initial_grade': initialGrade,
    'transmuted_grade': transmutedGrade,
    'is_locked': isLocked,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
  };

  Map<String, dynamic> toMap() => {
    CommonCols.id: id,
    TermGradesCols.classId: classId,
    TermGradesCols.studentId: studentId,
    TermGradesCols.termNumber: termNumber,
    TermGradesCols.initialGrade: initialGrade,
    TermGradesCols.transmutedGrade: transmutedGrade,
    TermGradesCols.isLocked: isLocked ? 1 : 0,
    CommonCols.createdAt: createdAt.toIso8601String(),
    CommonCols.updatedAt: updatedAt.toIso8601String(),
    CommonCols.cachedAt: DateTime.now().toIso8601String(),
    CommonCols.syncStatus: 'synced',
  };
}
