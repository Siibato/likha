import 'package:likha/core/sync/mutation_result.dart';
import 'package:likha/core/utils/typedef.dart';
import 'package:likha/domain/assessments/entities/assessment.dart';
import 'package:likha/domain/assessments/entities/assessment_statistics.dart';
import 'package:likha/domain/assessments/entities/question.dart';
import 'package:likha/domain/assessments/entities/submission.dart';

abstract class AssessmentRepository {
  // Teacher: Assessment CRUD
  ResultFuture<MutationResult<Assessment>> createAssessment({
    required String classId,
    required String title,
    String? description,
    required int timeLimitMinutes,
    required String openAt,
    required String closeAt,
    bool? showResultsImmediately,
    bool isPublished = true,
    List<Map<String, dynamic>>? questions,
    int? gradingPeriodNumber,
    String? component,
    String? tosId,
  });

  ResultFuture<List<Assessment>> getAssessments({required String classId, bool publishedOnly = false, bool skipBackgroundRefresh = false});

  ResultFuture<(Assessment, List<Question>)> getAssessmentDetail({required String assessmentId, bool skipBackgroundRefresh = false});

  ResultFuture<MutationResult<Assessment>> updateAssessment({
    required String assessmentId,
    String? title,
    String? description,
    int? timeLimitMinutes,
    String? openAt,
    String? closeAt,
    bool? showResultsImmediately,
    int? gradingPeriodNumber,
    String? component,
  });

  ResultFuture<MutationResult<void>> deleteAssessment({required String assessmentId});

  ResultFuture<MutationResult<Assessment>> publishAssessment({required String assessmentId});

  ResultFuture<MutationResult<Assessment>> unpublishAssessment({required String assessmentId});

  ResultFuture<MutationResult<Assessment>> releaseResults({required String assessmentId});

  ResultFuture<MutationResult<void>> reorderAllAssessments({
    required String classId,
    required List<String> assessmentIds,
  });

  // Teacher: Questions
  ResultFuture<MutationResult<List<Question>>> addQuestions({
    required String assessmentId,
    required List<Map<String, dynamic>> questions,
  });

  ResultFuture<MutationResult<Question>> updateQuestion({
    required String questionId,
    required Map<String, dynamic> data,
  });

  ResultFuture<MutationResult<void>> deleteQuestion({required String questionId});

  ResultFuture<MutationResult<void>> reorderQuestions({
    required String assessmentId,
    required List<String> questionIds,
  });

  // Teacher: Submissions & Grading
  ResultFuture<List<SubmissionSummary>> getSubmissions({
    required String assessmentId,
    bool skipBackgroundRefresh = false,
  });

  ResultFuture<SubmissionDetail?> getSubmissionDetail({
    required String submissionId,
    bool skipBackgroundRefresh = false,
  });

  ResultFuture<MutationResult<SubmissionAnswer>> overrideAnswer({
    required String answerId,
    required bool isCorrect,
    double? points,
  });

  ResultFuture<MutationResult<SubmissionAnswer>> gradeEssayAnswer({
    required String answerId,
    required double points,
  });

  ResultFuture<AssessmentStatistics> getStatistics({
    required String assessmentId,
  });

  // Student: Taking Assessments
  ResultFuture<MutationResult<StartSubmissionResult>> startAssessment({
    required String assessmentId,
    required String studentId,
    required String studentName,
    required String studentUsername,
  });

  ResultFuture<SubmissionSummary?> getStudentSubmission({
    required String assessmentId,
    required String studentId,
  });

  ResultFuture<MutationResult<void>> saveAnswers({
    required String submissionId,
    required List<Map<String, dynamic>> answers,
  });

  ResultFuture<MutationResult<SubmissionSummary>> submitAssessment({
    required String submissionId,
  });

  ResultFuture<StudentResult> getStudentResults({
    required String submissionId,
  });
}
