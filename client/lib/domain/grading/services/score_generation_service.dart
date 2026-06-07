import 'package:dartz/dartz.dart';
import 'package:likha/core/errors/failures.dart';
import 'package:likha/core/utils/typedef.dart';
import 'package:likha/core/logging/repo_logger.dart';
import 'package:likha/domain/assessments/entities/submission.dart';
import 'package:likha/domain/assignments/entities/assignment_submission.dart';
import 'package:likha/domain/grading/entities/grade_item.dart';
import 'package:likha/domain/grading/repositories/grading_repository.dart';
import 'package:likha/domain/assessments/repositories/assessment_repository.dart';
import 'package:likha/domain/assignments/repositories/assignment_repository.dart';

/// Service responsible for generating scores from assessment and assignment submissions
/// and populating the grade_scores table.
class ScoreGenerationService {
  final GradingRepository _gradingRepository;
  final AssessmentRepository _assessmentRepository;
  final AssignmentRepository _assignmentRepository;
  static final _logger = RepoLogger.instance;

  ScoreGenerationService({
    required GradingRepository gradingRepository,
    required AssessmentRepository assessmentRepository,
    required AssignmentRepository assignmentRepository,
  }) : _gradingRepository = gradingRepository,
       _assessmentRepository = assessmentRepository,
       _assignmentRepository = assignmentRepository;

  /// Generate scores for all grade items in a class for a specific grading period.
  ///
  /// [items] — when supplied, use these directly instead of fetching from the
  /// repository. Pass `state.items` from the provider to include locally-created
  /// items that have not yet synced to the server.
  ResultFuture<void> generateScoresForClass({
    required String classId,
    required int gradingPeriodNumber,
    List<GradeItem>? items,
  }) async {
    _logger.log('generateScoresForClass() - START: classId=$classId, period=$gradingPeriodNumber, providedItems=${items?.length}');

    try {
      List<GradeItem> gradeItems;

      if (items != null) {
        gradeItems = items;
        _logger.log('generateScoresForClass() - Using ${gradeItems.length} provided grade items');
      } else {
        _logger.log('generateScoresForClass() - Fetching grade items from repository...');
        final gradeItemsResult = await _gradingRepository.getGradeItems(
          classId: classId,
          gradingPeriodNumber: gradingPeriodNumber,
        );
        List<GradeItem>? fetched;
        Failure? fetchFailure;
        gradeItemsResult.fold(
          (f) => fetchFailure = f,
          (items) => fetched = items,
        );
        if (fetchFailure != null) {
          _logger.error('generateScoresForClass() - Failed to get grade items', fetchFailure);
          return Left(fetchFailure!);
        }
        gradeItems = fetched!;
        _logger.log('generateScoresForClass() - Fetched ${gradeItems.length} grade items');
      }

      for (final gradeItem in gradeItems) {
        _logger.log('generateScoresForClass() - Processing: ${gradeItem.title} (${gradeItem.id}) - source: ${gradeItem.sourceType}');
        final result = await generateScoresForGradeItem(gradeItem);
        if (result.isLeft()) {
          _logger.error('generateScoresForClass() - Failed for item ${gradeItem.id}', result);
          return result;
        }
      }

      _logger.log('generateScoresForClass() - SUCCESS: Generated scores for all items');
      return const Right(null);
    } catch (e) {
      _logger.error('generateScoresForClass() - Unexpected exception', e);
      return Left(CacheFailure(e.toString()));
    }
  }

  /// Generate scores for a specific grade item
  ResultFuture<void> generateScoresForGradeItem(GradeItem gradeItem) async {
    _logger.log('generateScoresForGradeItem() - START: ${gradeItem.title} (${gradeItem.id}) - type: ${gradeItem.sourceType}');
    
    try {
      // Check if the grade item is linked to an assessment
      if (gradeItem.sourceType == 'assessment' && gradeItem.sourceId != null) {
        _logger.log('generateScoresForGradeItem() - Generating from assessment sourceId: ${gradeItem.sourceId}');
        return await generateScoresFromAssessment(gradeItem);
      } else if (gradeItem.sourceType == 'assignment' && gradeItem.sourceId != null) {
        _logger.log('generateScoresForGradeItem() - Generating from assignment sourceId: ${gradeItem.sourceId}');
        return await generateScoresFromAssignment(gradeItem);
      } else {
        // For manual grade items, we don't auto-generate scores
        _logger.log('generateScoresForGradeItem() - Manual grade item, skipping score generation');
        return const Right(null);
      }
    } catch (e) {
      _logger.error('generateScoresForGradeItem() - Unexpected exception', e);
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
      _logger.log('generateScoresFromAssessment() - START: assessmentId=$assessmentId, gradeItemId=${gradeItem.id}');
      
      // Get all submissions for the assessment
      _logger.log('generateScoresFromAssessment() - Fetching submissions for assessment $assessmentId...');
      final submissionsResult = await _assessmentRepository.getSubmissions(
        assessmentId: assessmentId,
      );

      return submissionsResult.fold(
        (failure) {
          _logger.error('generateScoresFromAssessment() - Failed to get submissions', failure);
          return Left(failure);
        },
        (submissions) async {
          _logger.log('generateScoresFromAssessment() - Found ${submissions.length} submissions');
          final scores = <Map<String, dynamic>>[];
          int submittedCount = 0;

          for (final submission in submissions) {
            // Only generate scores for submitted assessments
            if (submission.isSubmitted) {
              submittedCount++;
              _logger.log('generateScoresFromAssessment() - Processing submission: ${submission.studentId} - finalScore: ${submission.finalScore}, autoScore: ${submission.autoScore}');
              final score = _calculateScoreFromSubmission(submission, gradeItem);
              scores.add(score);
              _logger.log('generateScoresFromAssessment() - Generated score: ${score['score']} for student ${score['student_id']}');
            } else {
              _logger.log('generateScoresFromAssessment() - Skipping unsubmitted submission: ${submission.studentId}');
            }
          }

          _logger.log('generateScoresFromAssessment() - Generated ${scores.length} scores from $submittedCount submitted submissions');
          
          // Save the scores even if empty to ensure score records exist
          _logger.log('generateScoresFromAssessment() - Saving ${scores.length} scores to grade item ${gradeItem.id}');
          final saveResult = await _gradingRepository.saveScores(
            gradeItemId: gradeItem.id,
            scores: scores,
          );
          
          return saveResult.fold(
            (failure) {
              _logger.error('generateScoresFromAssessment() - Failed to save scores', failure);
              return Left(failure);
            },
            (_) {
              _logger.log('generateScoresFromAssessment() - SUCCESS: Saved ${scores.length} scores');
              return const Right(null);
            }
          );
        },
      );
    } catch (e) {
      _logger.error('generateScoresFromAssessment() - Unexpected exception', e);
      return Left(CacheFailure(e.toString()));
    }
  }

  /// Generate scores from assignment submissions
  ResultFuture<void> generateScoresFromAssignment(GradeItem gradeItem) async {
    try {
      final assignmentId = gradeItem.sourceId!;
      _logger.log('generateScoresFromAssignment() - START: assignmentId=$assignmentId, gradeItemId=${gradeItem.id}');
      
      // Get all submissions for the assignment
      _logger.log('generateScoresFromAssignment() - Fetching submissions for assignment $assignmentId...');
      final submissionsResult = await _assignmentRepository.getSubmissions(
        assignmentId: assignmentId,
      );

      return submissionsResult.fold(
        (failure) {
          _logger.error('generateScoresFromAssignment() - Failed to get submissions', failure);
          return Left(failure);
        },
        (submissions) async {
          _logger.log('generateScoresFromAssignment() - Found ${submissions.length} submissions');
          final scores = <Map<String, dynamic>>[];
          int gradedCount = 0;

          for (final submission in submissions) {
            // Only generate scores for submitted assignments that have been graded
            if (submission.status == 'submitted' || submission.status == 'graded') {
              gradedCount++;
              _logger.log('generateScoresFromAssignment() - Processing submission: ${submission.studentId} - status: ${submission.status}, score: ${submission.score}');
              final score = _calculateScoreFromAssignmentSubmission(submission, gradeItem);
              scores.add(score);
              _logger.log('generateScoresFromAssignment() - Generated score: ${score['score']} for student ${score['student_id']}');
            } else {
              _logger.log('generateScoresFromAssignment() - Skipping submission with status ${submission.status}: ${submission.studentId}');
            }
          }

          _logger.log('generateScoresFromAssignment() - Generated ${scores.length} scores from $gradedCount graded submissions');
          
          // Save the scores even if empty to ensure score records exist
          _logger.log('generateScoresFromAssignment() - Saving ${scores.length} scores to grade item ${gradeItem.id}');
          final saveResult = await _gradingRepository.saveScores(
            gradeItemId: gradeItem.id,
            scores: scores,
          );
          
          return saveResult.fold(
            (failure) {
              _logger.error('generateScoresFromAssignment() - Failed to save scores', failure);
              return Left(failure);
            },
            (_) {
              _logger.log('generateScoresFromAssignment() - SUCCESS: Saved ${scores.length} scores');
              return const Right(null);
            }
          );
        },
      );
    } catch (e) {
      _logger.error('generateScoresFromAssignment() - Unexpected exception', e);
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

  /// Calculate score from assignment submission
  Map<String, dynamic> _calculateScoreFromAssignmentSubmission(
    SubmissionListItem submission,
    GradeItem gradeItem,
  ) {
    // Use the graded score if available, otherwise 0
    final score = submission.score ?? 0.0;
    
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
