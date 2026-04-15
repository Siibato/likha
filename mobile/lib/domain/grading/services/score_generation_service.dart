import 'package:dartz/dartz.dart';
import 'package:likha/core/errors/failures.dart';
import 'package:likha/core/utils/typedef.dart';
import 'package:likha/domain/assessments/entities/submission.dart';
import 'package:likha/domain/grading/entities/grade_item.dart';
import 'package:likha/domain/grading/repositories/grading_repository.dart';
import 'package:likha/domain/assessments/repositories/assessment_repository.dart';

/// Service responsible for generating scores from assessment submissions
/// and populating the grade_scores table.
class ScoreGenerationService {
  final GradingRepository _gradingRepository;
  final AssessmentRepository _assessmentRepository;

  ScoreGenerationService({
    required GradingRepository gradingRepository,
    required AssessmentRepository assessmentRepository,
  }) : _gradingRepository = gradingRepository,
       _assessmentRepository = assessmentRepository;

  /// Generate scores for all grade items in a class for a specific grading period
  ResultFuture<void> generateScoresForClass({
    required String classId,
    required int gradingPeriodNumber,
  }) async {
    try {
      // Get all grade items for the class and grading period
      final gradeItemsResult = await _gradingRepository.getGradeItems(
        classId: classId,
        gradingPeriodNumber: gradingPeriodNumber,
      );

      return gradeItemsResult.fold(
        (failure) => Left(failure),
        (gradeItems) async {
          // Generate scores for each grade item
          for (final gradeItem in gradeItems) {
            final result = await generateScoresForGradeItem(gradeItem);
            if (result.isLeft()) {
              return result;
            }
          }
          return const Right(null);
        },
      );
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  /// Generate scores for a specific grade item
  ResultFuture<void> generateScoresForGradeItem(GradeItem gradeItem) async {
    try {
      // Check if the grade item is linked to an assessment
      if (gradeItem.sourceType == 'assessment' && gradeItem.sourceId != null) {
        return await generateScoresFromAssessment(gradeItem);
      } else if (gradeItem.sourceType == 'assignment' && gradeItem.sourceId != null) {
        return await generateScoresFromAssignment(gradeItem);
      } else {
        // For manual grade items, we don't auto-generate scores
        return const Right(null);
      }
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  /// Generate scores for a specific grade item by ID
  ResultFuture<void> generateScoresForGradeItemById(String gradeItemId) async {
    try {
      // Get the grade item first
      final gradeItemsResult = await _gradingRepository.getGradeItems(
        classId: '', // We'll need to get the classId from the grade item
        gradingPeriodNumber: 1, // We'll need to get this from the grade item
      );

      return gradeItemsResult.fold(
        (failure) => Left(failure),
        (gradeItems) {
          final gradeItem = gradeItems.firstWhere(
            (item) => item.id == gradeItemId,
            orElse: () => throw Exception('Grade item not found'),
          );
          return generateScoresForGradeItem(gradeItem);
        },
      );
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  /// Generate scores from assessment submissions
  ResultFuture<void> generateScoresFromAssessment(GradeItem gradeItem) async {
    try {
      final assessmentId = gradeItem.sourceId!;
      
      // Get all submissions for the assessment
      final submissionsResult = await _assessmentRepository.getSubmissions(
        assessmentId: assessmentId,
      );

      return submissionsResult.fold(
        (failure) => Left(failure),
        (submissions) async {
          final scores = <Map<String, dynamic>>[];

          for (final submission in submissions) {
            // Only generate scores for submitted assessments
            if (submission.isSubmitted) {
              final score = _calculateScoreFromSubmission(submission, gradeItem);
              scores.add(score);
            }
          }

          // Save the scores
          if (scores.isNotEmpty) {
            return await _gradingRepository.saveScores(
              gradeItemId: gradeItem.id,
              scores: scores,
            );
          }

          return const Right(null);
        },
      );
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  /// Generate scores from assignment submissions
  ResultFuture<void> generateScoresFromAssignment(GradeItem gradeItem) async {
    try {
      // TODO: Implement assignment score generation
      // This would be similar to assessment score generation
      // but using assignment submission data
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  /// Calculate score from assessment submission
  Map<String, dynamic> _calculateScoreFromSubmission(
    SubmissionSummary submission,
    GradeItem gradeItem,
  ) {
    // Use the final score from the submission, or auto score if final score is not available
    final score = submission.finalScore > 0 ? submission.finalScore : submission.autoScore;
    
    return {
      'student_id': submission.studentId,
      'score': score,
      'is_auto_populated': true,
      'override_score': null,
    };
  }

  /// Generate a single score for a student and grade item
  Map<String, dynamic> generateSingleScore({
    required String studentId,
    required double score,
    bool isAutoPopulated = false,
    double? overrideScore,
  }) {
    return {
      'student_id': studentId,
      'score': score,
      'is_auto_populated': isAutoPopulated,
      'override_score': overrideScore,
    };
  }

  /// Check if scores exist for a grade item
  ResultFuture<bool> hasScoresForGradeItem(String gradeItemId) async {
    try {
      final scoresResult = await _gradingRepository.getScoresByItem(gradeItemId: gradeItemId);
      return scoresResult.fold(
        (failure) => Left(failure),
        (scores) => Right(scores.isNotEmpty),
      );
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  /// Get score summary for a grade item
  ResultFuture<Map<String, dynamic>> getScoreSummary(String gradeItemId) async {
    try {
      final scoresResult = await _gradingRepository.getScoresByItem(gradeItemId: gradeItemId);
      return scoresResult.fold(
        (failure) => Left(failure),
        (scores) {
          final submittedScores = scores.where((s) => s.score != null).toList();
          final averageScore = submittedScores.isNotEmpty
              ? submittedScores.map((s) => s.score!).reduce((a, b) => a + b) / submittedScores.length
              : 0.0;
          final highestScore = submittedScores.isNotEmpty
              ? submittedScores.map((s) => s.score!).reduce((a, b) => a > b ? a : b)
              : 0.0;
          final lowestScore = submittedScores.isNotEmpty
              ? submittedScores.map((s) => s.score!).reduce((a, b) => a < b ? a : b)
              : 0.0;

          return Right({
            'total_submissions': submittedScores.length,
            'average_score': averageScore,
            'highest_score': highestScore,
            'lowest_score': lowestScore,
          });
        },
      );
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }
}
