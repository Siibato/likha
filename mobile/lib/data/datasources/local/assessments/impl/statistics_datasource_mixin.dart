import 'dart:convert';
import 'package:likha/core/errors/exceptions.dart';
import 'package:likha/data/models/assessments/statistics_model.dart';
import 'package:likha/data/models/assessments/submission_model.dart';
import 'package:sqflite/sqflite.dart';
import '../assessment_local_datasource_base.dart';

mixin StatisticsDataSourceMixin on AssessmentLocalDataSourceBase {
  @override
  Future<AssessmentStatisticsModel?> getCachedStatistics(String assessmentId) async {
    try {
      final db = await localDatabase.database;
      final results = await db.query('assessment_statistics_cache', where: 'assessment_id = ?', whereArgs: [assessmentId]);
      if (results.isEmpty) return null;
      final statisticsJson = jsonDecode(results.first['statistics_json'] as String) as Map<String, dynamic>;
      return AssessmentStatisticsModel.fromJson(statisticsJson);
    } catch (e) {
      throw CacheException('Failed to get cached statistics: $e');
    }
  }

  @override
  Future<void> cacheStatistics(AssessmentStatisticsModel statistics) async {
    try {
      final db = await localDatabase.database;
      final statsJson = {
        'assessment_id': statistics.assessmentId,
        'title': statistics.title,
        'total_points': statistics.totalPoints,
        'submission_count': statistics.submissionCount,
        'class_statistics': {
          'mean': statistics.classStatistics.mean,
          'median': statistics.classStatistics.median,
          'highest': statistics.classStatistics.highest,
          'lowest': statistics.classStatistics.lowest,
          'score_distribution': statistics.classStatistics.scoreDistribution
              .map((b) => {'range': b.range, 'count': b.count})
              .toList(),
        },
        'question_statistics': statistics.questionStatistics.map((qs) => {
          'question_id': qs.questionId,
          'question_text': qs.questionText,
          'question_type': qs.questionType,
          'points': qs.points,
          'correct_count': qs.correctCount,
          'incorrect_count': qs.incorrectCount,
          'correct_percentage': qs.correctPercentage,
        }).toList(),
      };
      await db.insert(
        'assessment_statistics_cache',
        {'assessment_id': statistics.assessmentId, 'statistics_json': jsonEncode(statsJson), 'cached_at': DateTime.now().toIso8601String()},
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      throw CacheException('Failed to cache statistics: $e');
    }
  }

  @override
  Future<StudentResultModel?> getCachedStudentResults(String submissionId) async {
    try {
      final db = await localDatabase.database;
      final results = await db.query('student_results_cache', where: 'submission_id = ?', whereArgs: [submissionId]);
      if (results.isEmpty) return null;
      final resultsJson = jsonDecode(results.first['results_json'] as String) as Map<String, dynamic>;
      return StudentResultModel.fromJson(resultsJson);
    } catch (e) {
      throw CacheException('Failed to get cached student results: $e');
    }
  }

  @override
  Future<void> cacheStudentResults(StudentResultModel result) async {
    try {
      final db = await localDatabase.database;
      final resultsJson = {
        'submission_id': result.submissionId,
        'auto_score': result.autoScore,
        'final_score': result.finalScore,
        'total_points': result.totalPoints,
        'submitted_at': result.submittedAt?.toIso8601String(),
        'answers': result.answers.map((ans) => {
          'question_id': ans.questionId,
          'question_text': ans.questionText,
          'question_type': ans.questionType,
          'points': ans.points,
          'points_awarded': ans.pointsAwarded,
          'is_correct': ans.isCorrect,
          'answer_text': ans.answerText,
          'selected_choices': ans.selectedChoices,
          'enumeration_answers': ans.enumerationAnswers?.map((ea) => {'answer_text': ea.answerText, 'is_correct': ea.isCorrect}).toList(),
          'correct_answers': ans.correctAnswers,
        }).toList(),
      };
      await db.insert(
        'student_results_cache',
        {'submission_id': result.submissionId, 'results_json': jsonEncode(resultsJson), 'cached_at': DateTime.now().toIso8601String()},
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      throw CacheException('Failed to cache student results: $e');
    }
  }
}