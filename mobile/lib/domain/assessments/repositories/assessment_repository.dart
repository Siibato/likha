import 'package:likha/core/utils/typedef.dart';
import 'package:likha/domain/assessments/entities/assessment.dart';
import 'package:likha/domain/assessments/entities/assessment_statistics.dart';
import 'package:likha/domain/assessments/entities/question.dart';
import 'package:likha/domain/assessments/entities/submission.dart';

abstract class AssessmentRepository {
  // Teacher: Assessment CRUD
  ResultFuture<Assessment> createAssessment({
    required String classId,
    required String title,
    String? description,
    required int timeLimitMinutes,
    required String openAt,
    required String closeAt,
    bool? showResultsImmediately,
    bool isPublished = true,
    List<Map<String, dynamic>>? questions,
  });

  ResultFuture<List<Assessment>> getAssessments({required String classId, bool publishedOnly = false, bool skipBackgroundRefresh = false});

  ResultFuture<(Assessment, List<Question>)> getAssessmentDetail({required String assessmentId});

  ResultFuture<Assessment> updateAssessment({
    required String assessmentId,
    String? title,
    String? description,
    int? timeLimitMinutes,
    String? openAt,
    String? closeAt,
    bool? showResultsImmediately,
  });

  ResultVoid deleteAssessment({required String assessmentId});

  ResultFuture<Assessment> publishAssessment({required String assessmentId});

  ResultFuture<Assessment> unpublishAssessment({required String assessmentId});

  ResultFuture<Assessment> releaseResults({required String assessmentId});

  ResultVoid reorderAllAssessments({
    required String classId,
    required List<String> assessmentIds,
  });

  // Teacher: Questions
  ResultFuture<List<Question>> addQuestions({
    required String assessmentId,
    required List<Map<String, dynamic>> questions,
  });

  ResultFuture<Question> updateQuestion({
    required String questionId,
    required Map<String, dynamic> data,
  });

  ResultVoid deleteQuestion({required String questionId});

  ResultVoid reorderQuestions({
    required String assessmentId,
    required List<String> questionIds,
  });

  // Teacher: Submissions & Grading
  ResultFuture<List<SubmissionSummary>> getSubmissions({
    required String assessmentId,
  });

  ResultFuture<SubmissionDetail> getSubmissionDetail({
    required String submissionId,
  });

  ResultFuture<SubmissionAnswer> overrideAnswer({
    required String answerId,
    required bool isCorrect,
  });

  ResultFuture<AssessmentStatistics> getStatistics({
    required String assessmentId,
  });

  // Student: Taking Assessments
  ResultFuture<StartSubmissionResult> startAssessment({
    required String assessmentId,
    required String studentId,
    required String studentName,
    required String studentUsername,
  });

  ResultFuture<SubmissionSummary?> getStudentSubmission({
    required String assessmentId,
    required String studentId,
  });

  ResultVoid saveAnswers({
    required String submissionId,
    required List<Map<String, dynamic>> answers,
  });

  ResultFuture<SubmissionSummary> submitAssessment({
    required String submissionId,
  });

  ResultFuture<StudentResult> getStudentResults({
    required String submissionId,
  });
}
