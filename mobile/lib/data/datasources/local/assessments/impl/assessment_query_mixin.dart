import 'dart:convert';
import 'package:likha/core/errors/exceptions.dart';
import 'package:likha/data/models/assessments/assessment_model.dart';
import 'package:likha/data/models/assessments/question_model.dart';
import '../assessment_local_datasource_base.dart';

mixin AssessmentQueryMixin on AssessmentLocalDataSourceBase {
  @override
  Future<List<AssessmentModel>> getCachedAssessments(String classId) async {
    try {
      final db = await localDatabase.database;
      final results = await db.query(
        'assessments',
        where: 'class_id = ?',
        whereArgs: [classId],
        orderBy: 'created_at DESC',
      );
      if (results.isEmpty) throw CacheException('No cached assessments for class $classId');
      return results.map(AssessmentModel.fromMap).toList();
    } catch (e) {
      if (e is CacheException) rethrow;
      throw CacheException(e.toString());
    }
  }

  @override
  Future<(AssessmentModel, List<QuestionModel>)> getCachedAssessmentDetail(String assessmentId) async {
    try {
      final db = await localDatabase.database;
      final assessmentResults = await db.query(
        'assessments',
        where: 'id = ?',
        whereArgs: [assessmentId],
      );
      if (assessmentResults.isEmpty) throw CacheException('Assessment $assessmentId not cached');

      final assessment = AssessmentModel.fromMap(assessmentResults.first);
      final questionResults = await db.query(
        'questions',
        where: 'assessment_id = ?',
        whereArgs: [assessmentId],
        orderBy: 'order_index ASC',
      );
      final questions = questionResults
          .map((q) => QuestionModel.fromJson(jsonDecode(jsonEncode(q))))
          .toList();

      return (assessment, questions);
    } catch (e) {
      if (e is CacheException) rethrow;
      throw CacheException(e.toString());
    }
  }
}