import 'package:likha/data/models/assessments/assessment_model.dart';
import 'package:likha/data/models/assessments/question_model.dart';
import 'package:likha/data/models/assessments/submission_model.dart';
import 'package:likha/data/models/assessments/statistics_model.dart';

abstract class AssessmentLocalDataSource {
  Future<List<AssessmentModel>> getCachedAssessments(String classId, {bool publishedOnly = false});
  Future<(AssessmentModel, List<QuestionModel>)> getCachedAssessmentDetail(String assessmentId);
  Future<void> cacheAssessments(List<AssessmentModel> assessments);
  Future<void> cacheAssessmentDetail(AssessmentModel assessment, List<QuestionModel> questions);
  Future<void> cacheQuestions(String assessmentId, List<QuestionModel> questions, {bool isServerConfirmed = false});
  Future<void> updateQuestion({
    required String questionId,
    required Map<String, dynamic> updates,
    bool isOfflineMutation = true,
  });
  Future<void> deleteQuestion({required String questionId});
  Future<void> deleteAssessment({required String assessmentId});
  Future<QuestionModel?> getCachedQuestion(String questionId);
  Future<void> updateQuestionId({
    required String localId,
    required String serverId,
  });
  Future<void> updateChoiceIds({
    required String questionId,
    required Map<String, String> idMapping,
  });
  Future<void> updateCorrectAnswerIds({
    required String questionId,
    required Map<String, String> idMapping,
  });
  Future<void> saveAnswers({
    required String submissionId,
    required String answersJson,
  });
  Future<void> cacheStartSubmissionResult({
    required String submissionId,
    required String assessmentId,
    required String studentId,
    required String studentName,
    required String studentUsername,
    required DateTime startedAt,
  });
  Future<String> startAssessment({
    required String assessmentId,
    required String studentId,
    required String studentName,
    required String studentUsername,
  });
  Future<StartSubmissionResultModel?> getCachedStartResult(String submissionId);
  Future<SubmissionSummaryModel?> getCachedStudentSubmission(
    String assessmentId,
    String studentId,
  );
  Future<void> submitAssessment({
    required String submissionId,
    required String assessmentId,
  });
  Future<SubmissionDetailModel?> getCachedSubmissionDetail(String submissionId);
  Future<void> cacheSubmissionDetail(SubmissionDetailModel submission);
  Future<String> createAssessment({
    required String classId,
    required String title,
    String? description,
    required int timeLimitMinutes,
    required String openAt,
    required String closeAt,
    bool? showResultsImmediately,
    bool isPublished = true,
    String? tosId,
    int? gradingPeriodNumber,
    String? component,
  });
  Future<String> createAssessmentWithQuestions({
    required String classId,
    required String title,
    String? description,
    required int timeLimitMinutes,
    required String openAt,
    required String closeAt,
    bool? showResultsImmediately,
    required List<QuestionModel> questions,
    bool isPublished = true,
    String? linkedTosId,
    int? quarter,
    String? component,
  });
  Future<List<SubmissionSummaryModel>> getCachedSubmissions(String assessmentId);
  Future<int> getCachedSubmissionCount(String assessmentId);
  Future<bool?> hasStudentSubmittedAssessment(String assessmentId, String studentId);
  Future<void> cacheSubmissions(String assessmentId, List<SubmissionSummaryModel> submissions);
  Future<AssessmentStatisticsModel?> getCachedStatistics(String assessmentId);
  Future<void> cacheStatistics(AssessmentStatisticsModel statistics);
  Future<StudentResultModel?> getCachedStudentResults(String submissionId);
  Future<void> cacheStudentResults(StudentResultModel result);
  Future<void> releaseResults({required String assessmentId});
  Future<void> overrideAnswer({
    required String answerId,
    required bool isCorrect,
    double? points,
  });
  Future<void> gradeEssay({
    required String answerId,
    required double points,
  });
  Future<void> markAssessmentPublished({required String assessmentId});
  Future<void> markAssessmentUnpublished({required String assessmentId});
  Future<void> clearAllCache();
}