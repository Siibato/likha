import 'package:likha/core/database/local_database.dart';
import 'package:likha/core/sync/sync_queue.dart';
import 'package:likha/data/models/assessments/assessment_model.dart';
import 'package:likha/data/models/assessments/question_model.dart';
import 'package:likha/data/models/assessments/submission_model.dart';
import 'package:likha/data/models/assessments/statistics_model.dart';
import 'assessment_local_datasource.dart';
import 'operations/assessments.dart' as ops;

class AssessmentLocalDataSourceImpl implements AssessmentLocalDataSource {
  final LocalDatabase localDatabase;
  final SyncQueue syncQueue;

  AssessmentLocalDataSourceImpl(this.localDatabase, this.syncQueue);

  @override
  Future<List<AssessmentModel>> getCachedAssessments(
    String classId, {
    bool publishedOnly = false,
  }) =>
      ops.getCachedAssessments(localDatabase, classId, publishedOnly: publishedOnly);

  @override
  Future<(AssessmentModel, List<QuestionModel>)> getCachedAssessmentDetail(
    String assessmentId,
  ) =>
      ops.getCachedAssessmentDetail(localDatabase, assessmentId);

  @override
  Future<void> cacheAssessments(List<AssessmentModel> assessments) =>
      ops.cacheAssessments(localDatabase, assessments);

  @override
  Future<void> cacheAssessmentDetail(
    AssessmentModel assessment,
    List<QuestionModel> questions,
  ) =>
      ops.cacheAssessmentDetail(localDatabase, assessment, questions);

  @override
  Future<void> cacheQuestions(
    String assessmentId,
    List<QuestionModel> questions, {
    bool isServerConfirmed = false,
  }) =>
      ops.cacheQuestions(
        localDatabase,
        assessmentId,
        questions,
        isServerConfirmed: isServerConfirmed,
      );

  @override
  Future<void> updateQuestion({
    required String questionId,
    required Map<String, dynamic> updates,
    bool isOfflineMutation = true,
  }) =>
      ops.updateQuestion(localDatabase, questionId, updates, isOfflineMutation);

  @override
  Future<void> deleteQuestion({required String questionId}) =>
      ops.deleteQuestion(localDatabase, questionId);

  @override
  Future<void> deleteAssessment({required String assessmentId}) =>
      ops.deleteAssessment(localDatabase, assessmentId);

  @override
  Future<QuestionModel?> getCachedQuestion(String questionId) =>
      ops.getCachedQuestion(localDatabase, questionId);

  @override
  Future<void> updateQuestionId({
    required String localId,
    required String serverId,
  }) =>
      ops.updateQuestionId(localDatabase, localId, serverId);

  @override
  Future<void> updateChoiceIds({
    required String questionId,
    required Map<String, String> idMapping,
  }) =>
      ops.updateChoiceIds(localDatabase, questionId, idMapping);

  @override
  Future<void> updateCorrectAnswerIds({
    required String questionId,
    required Map<String, String> idMapping,
  }) =>
      ops.updateCorrectAnswerIds(localDatabase, questionId, idMapping);

  @override
  Future<void> saveAnswers({
    required String submissionId,
    required String answersJson,
  }) =>
      ops.saveAnswers(localDatabase, syncQueue, submissionId, answersJson);

  @override
  Future<void> cacheStartSubmissionResult({
    required String submissionId,
    required String assessmentId,
    required String studentId,
    required String studentName,
    required String studentUsername,
    required DateTime startedAt,
  }) =>
      ops.cacheStartSubmissionResult(
        localDatabase,
        submissionId,
        assessmentId,
        studentId,
        studentName,
        studentUsername,
        startedAt,
      );

  @override
  Future<String> startAssessment({
    required String assessmentId,
    required String studentId,
    required String studentName,
    required String studentUsername,
  }) =>
      ops.startAssessment(
        localDatabase,
        syncQueue,
        assessmentId,
        studentId,
        studentName,
        studentUsername,
      );

  @override
  Future<StartSubmissionResultModel?> getCachedStartResult(String submissionId) =>
      ops.getCachedStartResult(localDatabase, submissionId);

  @override
  Future<SubmissionSummaryModel?> getCachedStudentSubmission(
    String assessmentId,
    String studentId,
  ) =>
      ops.getCachedStudentSubmission(localDatabase, assessmentId, studentId);

  @override
  Future<void> submitAssessment({
    required String submissionId,
    required String assessmentId,
  }) =>
      ops.submitAssessment(localDatabase, syncQueue, submissionId, assessmentId);

  @override
  Future<SubmissionDetailModel?> getCachedSubmissionDetail(String submissionId) =>
      ops.getCachedSubmissionDetail(localDatabase, submissionId);

  @override
  Future<void> cacheSubmissionDetail(SubmissionDetailModel submission) =>
      ops.cacheSubmissionDetail(localDatabase, submission);

  @override
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
  }) =>
      ops.createAssessment(
        localDatabase,
        syncQueue,
        classId,
        title,
        description,
        timeLimitMinutes,
        openAt,
        closeAt,
        showResultsImmediately,
        isPublished,
        tosId,
        gradingPeriodNumber,
        component,
      );

  @override
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
  }) =>
      ops.createAssessmentWithQuestions(
        localDatabase,
        syncQueue,
        classId,
        title,
        description,
        timeLimitMinutes,
        openAt,
        closeAt,
        showResultsImmediately,
        questions,
        isPublished,
        linkedTosId,
        quarter,
        component,
      );

  @override
  Future<List<SubmissionSummaryModel>> getCachedSubmissions(String assessmentId) =>
      ops.getCachedSubmissions(localDatabase, assessmentId);

  @override
  Future<int> getCachedSubmissionCount(String assessmentId) =>
      ops.getCachedSubmissionCount(localDatabase, assessmentId);

  @override
  Future<bool?> hasStudentSubmittedAssessment(String assessmentId, String studentId) =>
      ops.hasStudentSubmittedAssessment(localDatabase, assessmentId, studentId);

  @override
  Future<void> cacheSubmissions(
    String assessmentId,
    List<SubmissionSummaryModel> submissions,
  ) =>
      ops.cacheSubmissions(localDatabase, assessmentId, submissions);

  @override
  Future<AssessmentStatisticsModel?> getCachedStatistics(String assessmentId) =>
      ops.getCachedStatistics(localDatabase, assessmentId);

  @override
  Future<void> cacheStatistics(AssessmentStatisticsModel statistics) =>
      ops.cacheStatistics(localDatabase, statistics);

  @override
  Future<StudentResultModel?> getCachedStudentResults(String submissionId) =>
      ops.getCachedStudentResults(localDatabase, submissionId);

  @override
  Future<void> cacheStudentResults(StudentResultModel result) =>
      ops.cacheStudentResults(localDatabase, result);

  @override
  Future<void> releaseResults({required String assessmentId}) =>
      ops.releaseResults(localDatabase, syncQueue, assessmentId);

  @override
  Future<void> overrideAnswer({
    required String answerId,
    required bool isCorrect,
    double? points,
  }) =>
      ops.overrideAnswer(localDatabase, syncQueue, answerId, isCorrect, points);

  @override
  Future<void> gradeEssay({
    required String answerId,
    required double points,
  }) =>
      ops.gradeEssay(localDatabase, syncQueue, answerId, points);

  @override
  Future<void> markAssessmentPublished({required String assessmentId}) =>
      ops.markAssessmentPublished(localDatabase, assessmentId);

  @override
  Future<void> markAssessmentUnpublished({required String assessmentId}) =>
      ops.markAssessmentUnpublished(localDatabase, assessmentId);

  @override
  Future<void> clearAllCache() =>
      ops.clearAllCache(localDatabase);
}
