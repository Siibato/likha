import 'package:likha/core/database/db_schema.dart';
import 'package:likha/core/database/local_database.dart';
import 'package:likha/core/errors/exceptions.dart';
import 'package:sqflite_sqlcipher/sqflite.dart';
import 'package:uuid/uuid.dart';

Future<String> createAssessment(
  LocalDatabase localDatabase,
  String classId,
  String title,
  String? description,
  int timeLimitMinutes,
  String openAt,
  String closeAt,
  bool? showResultsImmediately,
  bool isPublished,
  String? tosId,
  int? gradingPeriodNumber,
  String? component, {
  String? id,
  Transaction? txn,
}) async {
  try {
    final db = await localDatabase.database;
    final now = DateTime.now();
    final assessmentId = id ?? const Uuid().v4();
    final map = {
      CommonCols.id: assessmentId,
      AssessmentsCols.classId: classId,
      AssessmentsCols.title: title,
      AssessmentsCols.description: description,
      AssessmentsCols.timeLimitMinutes: timeLimitMinutes,
      AssessmentsCols.openAt: openAt,
      AssessmentsCols.closeAt: closeAt,
      AssessmentsCols.showResultsImmediately: showResultsImmediately == true ? 1 : 0,
      AssessmentsCols.resultsReleased: 0,
      AssessmentsCols.isPublished: isPublished ? 1 : 0,
      AssessmentsCols.orderIndex: 0,
      if (tosId != null) AssessmentsCols.tosId: tosId,
      if (gradingPeriodNumber != null) AssessmentsCols.gradingPeriodNumber: gradingPeriodNumber,
      if (component != null) AssessmentsCols.component: component,
      CommonCols.createdAt: now.toIso8601String(),
      CommonCols.updatedAt: now.toIso8601String(),
      CommonCols.cachedAt: now.toIso8601String(),
      CommonCols.syncStatus: 'pending',
    };

    if (txn != null) {
      await txn.insert(DbTables.assessments, map);
    } else {
      await db.insert(DbTables.assessments, map);
    }

    return assessmentId;
  } catch (e) {
    throw CacheException('Failed to create assessment locally: $e');
  }
}
