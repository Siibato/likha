import 'package:likha/core/database/db_schema.dart';
import 'package:likha/core/sync/sync_queue.dart';

class GradeScoreModel {
  final String id;
  final String gradeItemId;
  final String studentId;
  final double? score;
  final bool isAutoPopulated;
  final double? overrideScore;
  final String createdAt;
  final String updatedAt;
  final String? syncStatus;

  const GradeScoreModel({
    required this.id,
    required this.gradeItemId,
    required this.studentId,
    this.score,
    required this.isAutoPopulated,
    this.overrideScore,
    required this.createdAt,
    required this.updatedAt,
    this.syncStatus,
  });

  double? get effectiveScore => overrideScore ?? score;

  factory GradeScoreModel.fromJson(Map<String, dynamic> json) {
    final now = DateTime.now().toIso8601String();
    return GradeScoreModel(
      id: json['id'] as String,
      gradeItemId: json['grade_item_id'] as String,
      studentId: json['student_id'] as String,
      score: json['score'] != null ? (json['score'] as num).toDouble() : null,
      isAutoPopulated: json['is_auto_populated'] == true,
      overrideScore: json['override_score'] != null ? (json['override_score'] as num).toDouble() : null,
      createdAt: (json['created_at'] as String?) ?? now,
      updatedAt: (json['updated_at'] as String?) ?? (json['created_at'] as String?) ?? now,
      syncStatus: json['sync_status'] as String? ?? SyncStatus.synced.dbValue,
    );
  }

  factory GradeScoreModel.fromMap(Map<String, dynamic> map) {
    return GradeScoreModel(
      id: map[CommonCols.id] as String,
      gradeItemId: map[GradeScoresCols.gradeItemId] as String,
      studentId: map[GradeScoresCols.studentId] as String,
      score: map[GradeScoresCols.score] != null ? (map[GradeScoresCols.score] as num).toDouble() : null,
      isAutoPopulated: map[GradeScoresCols.isAutoPopulated] == 1,
      overrideScore: map[GradeScoresCols.overrideScore] != null ? (map[GradeScoresCols.overrideScore] as num).toDouble() : null,
      createdAt: map[CommonCols.createdAt] as String,
      updatedAt: map[CommonCols.updatedAt] as String,
      syncStatus: map[CommonCols.syncStatus] as String? ?? SyncStatus.synced.dbValue,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'grade_item_id': gradeItemId,
    'student_id': studentId,
    'score': score,
    'is_auto_populated': isAutoPopulated,
    'override_score': overrideScore,
    'created_at': createdAt,
    'updated_at': updatedAt,
    'sync_status': syncStatus ?? SyncStatus.synced.dbValue,
  };

  Map<String, dynamic> toMap() => {
    CommonCols.id: id,
    GradeScoresCols.gradeItemId: gradeItemId,
    GradeScoresCols.studentId: studentId,
    GradeScoresCols.score: score,
    GradeScoresCols.isAutoPopulated: isAutoPopulated ? 1 : 0,
    GradeScoresCols.overrideScore: overrideScore,
    CommonCols.createdAt: createdAt,
    CommonCols.updatedAt: updatedAt,
    CommonCols.cachedAt: DateTime.now().toIso8601String(),
    CommonCols.syncStatus: syncStatus ?? SyncStatus.synced.dbValue,
  };
}
