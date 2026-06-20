import 'package:likha/core/database/local_database.dart';
import 'package:likha/core/sync/sync_queue.dart';
import 'package:likha/data/models/assessments/assessment_model.dart';
import 'package:likha/data/models/assessments/question_model.dart';
import 'package:likha/data/models/assessments/submission_model.dart';
import 'package:likha/data/models/assessments/statistics_model.dart';
import 'operations/assessments.dart' as ops;

abstract class AssessmentLocalDataSource {
  LocalDatabase get localDatabase;

  Future<List<AssessmentModel>> getCachedAssessments(String classId, {bool publishedOnly = false});
  Future<(AssessmentModel, List<QuestionModel>)> getCachedAssessmentDetail(String assessmentId);
  Future<void> cacheAssessments(
    List<AssessmentModel> assessments, {
    bool isServerConfirmed = true,
    Transaction? txn,
  });
  Future<void> cacheAssessmentDetail(AssessmentModel assessment, List<QuestionModel> questions);
  Future<void> cacheQuestions(
    String assessmentId,
    List<QuestionModel> questions, {
    bool isServerConfirmed = false,
    Transaction? txn,
  });
  Future<void> updateQuestion({
    required String questionId,
    required Map<String, dynamic> updates,
    bool isOfflineMutation = true,
    Transaction? txn,
  });
  Future<void> deleteQuestion({required String questionId, Transaction? txn});
  Future<void> deleteAssessment({required String assessmentId, Transaction? txn});
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
    Transaction? txn,
  });
  Future<void> cacheStartSubmissionResult({
    required String submissionId,
    required String assessmentId,
    required String studentId,
    required String studentName,
    required String studentUsername,
    required DateTime startedAt,
    Transaction? txn,
  });
  Future<String> startAssessment({
    required String assessmentId,
    required String studentId,
    required String studentName,
    required String studentUsername,
    Transaction? txn,
  });
  Future<StartSubmissionResultModel?> getCachedStartResult(String submissionId);
  Future<SubmissionSummaryModel?> getCachedStudentSubmission(
    String assessmentId,
    String studentId,
  );
  Future<void> cacheStudentSubmission(
    String assessmentId,
    String studentId,
    SubmissionSummaryModel? submission,
  );
  Future<void> submitAssessment({
    required String submissionId,
    required String assessmentId,
    Transaction? txn,
  });
  Future<SubmissionDetailModel?> getCachedSubmissionDetail(String submissionId);
  Future<void> cacheSubmissionDetail(SubmissionDetailModel submission);
  Future<String> createAssessment({
    String? id,
    required String classId,
    required String title,
    String? description,
    required int timeLimitMinutes,
    required String openAt,
    required String closeAt,
    bool? showResultsImmediately,
    bool isPublished = true,
    String? tosId,
    int? termNumber,
    String? component,
    Transaction? txn,
  });
  Future<String> createAssessmentWithQuestions({
    String? id,
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
    Transaction? txn,
  });
  Future<List<SubmissionSummaryModel>> getCachedSubmissions(String assessmentId);
  Future<int> getCachedSubmissionCount(String assessmentId);
  Future<bool?> hasStudentSubmittedAssessment(String assessmentId, String studentId);
  Future<void> cacheSubmissions(String assessmentId, List<SubmissionSummaryModel> submissions);
  Future<AssessmentStatisticsModel?> computeStatistics(String assessmentId);
  Future<StudentResultModel?> getCachedStudentResults(String submissionId);
  Future<void> cacheStudentResults(StudentResultModel result);
  Future<void> releaseResults({required String assessmentId, Transaction? txn});
  Future<void> overrideAnswer({
    required String answerId,
    required bool isCorrect,
    double? points,
    Transaction? txn,
  });
  Future<void> gradeEssay({
    required String answerId,
    required double points,
    Transaction? txn,
  });
  Future<void> markAssessmentPublished({required String assessmentId, Transaction? txn});
  Future<void> markAssessmentUnpublished({required String assessmentId, Transaction? txn});
  Future<void> updateAssessmentOrder({
    required String assessmentId,
    required int orderIndex,
    Transaction? txn,
  });
  Future<void> updateQuestionOrder({
    required String questionId,
    required int orderIndex,
    Transaction? txn,
  });
  Future<void> clearAllCache();
}

class AssessmentLocalDataSourceImpl implements AssessmentLocalDataSource {
  @override
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
  Future<void> cacheAssessments(
    List<AssessmentModel> assessments, {
    bool isServerConfirmed = true,
    Transaction? txn,
  }) =>
      ops.cacheAssessments(
        localDatabase,
        assessments,
        isServerConfirmed: isServerConfirmed,
        txn: txn,
      );

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
    Transaction? txn,
  }) =>
      ops.cacheQuestions(
        localDatabase,
        assessmentId,
        questions,
        isServerConfirmed: isServerConfirmed,
        txn: txn,
      );

  @override
  Future<void> updateQuestion({
    required String questionId,
    required Map<String, dynamic> updates,
    bool isOfflineMutation = true,
    Transaction? txn,
  }) =>
      ops.updateQuestion(localDatabase, questionId, updates, isOfflineMutation, txn: txn);

  @override
  Future<void> deleteQuestion({required String questionId, Transaction? txn}) =>
      ops.deleteQuestion(localDatabase, questionId, txn: txn);

  @override
  Future<void> deleteAssessment({required String assessmentId, Transaction? txn}) =>
      ops.deleteAssessment(localDatabase, assessmentId, txn: txn);

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
    Transaction? txn,
  }) =>
      ops.saveAnswers(localDatabase, submissionId, answersJson, txn: txn);

  @override
  Future<void> cacheStartSubmissionResult({
    required String submissionId,
    required String assessmentId,
    required String studentId,
    required String studentName,
    required String studentUsername,
    required DateTime startedAt,
    Transaction? txn,
  }) =>
      ops.cacheStartSubmissionResult(
        localDatabase,
        submissionId,
        assessmentId,
        studentId,
        studentName,
        studentUsername,
        startedAt,
        txn: txn,
      );

  @override
  Future<String> startAssessment({
    required String assessmentId,
    required String studentId,
    required String studentName,
    required String studentUsername,
    Transaction? txn,
  }) =>
      ops.startAssessment(
        localDatabase,
        assessmentId,
        studentId,
        studentName,
        studentUsername,
        txn: txn,
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
  Future<void> cacheStudentSubmission(
    String assessmentId,
    String studentId,
    SubmissionSummaryModel? submission,
  ) =>
      ops.cacheStudentSubmission(localDatabase, assessmentId, studentId, submission);

  @override
  Future<void> submitAssessment({
    required String submissionId,
    required String assessmentId,
    Transaction? txn,
  }) =>
      ops.submitAssessment(localDatabase, submissionId, assessmentId, txn: txn);

  @override
  Future<SubmissionDetailModel?> getCachedSubmissionDetail(String submissionId) =>
      ops.getCachedSubmissionDetail(localDatabase, submissionId);

  @override
  Future<void> cacheSubmissionDetail(SubmissionDetailModel submission) =>
      ops.cacheSubmissionDetail(localDatabase, submission);

  @override
  Future<String> createAssessment({
    String? id,
    required String classId,
    required String title,
    String? description,
    required int timeLimitMinutes,
    required String openAt,
    required String closeAt,
    bool? showResultsImmediately,
    bool isPublished = true,
    String? tosId,
    int? termNumber,
    String? component,
    Transaction? txn,
  }) =>
      ops.createAssessment(
        localDatabase,
        classId,
        title,
        description,
        timeLimitMinutes,
        openAt,
        closeAt,
        showResultsImmediately,
        isPublished,
        tosId,
        termNumber,
        component,
        id: id,
        txn: txn,
      );

  @override
  Future<String> createAssessmentWithQuestions({
    String? id,
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
    Transaction? txn,
  }) =>
      ops.createAssessmentWithQuestions(
        localDatabase,
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
        id: id,
        txn: txn,
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
  Future<AssessmentStatisticsModel?> computeStatistics(String assessmentId) =>
      ops.computeStatistics(localDatabase, assessmentId);

  @override
  Future<StudentResultModel?> getCachedStudentResults(String submissionId) =>
      ops.getCachedStudentResults(localDatabase, submissionId);

  @override
  Future<void> cacheStudentResults(StudentResultModel result) =>
      ops.cacheStudentResults(localDatabase, result);

  @override
  Future<void> releaseResults({required String assessmentId, Transaction? txn}) =>
      ops.releaseResults(localDatabase, assessmentId, txn: txn);

  @override
  Future<void> overrideAnswer({
    required String answerId,
    required bool isCorrect,
    double? points,
    Transaction? txn,
  }) =>
      ops.overrideAnswer(localDatabase, answerId, isCorrect, points, txn: txn);

  @override
  Future<void> gradeEssay({
    required String answerId,
    required double points,
    Transaction? txn,
  }) =>
      ops.gradeEssay(localDatabase, answerId, points, txn: txn);

  @override
  Future<void> markAssessmentPublished({required String assessmentId, Transaction? txn}) =>
      ops.markAssessmentPublished(localDatabase, assessmentId, txn: txn);

  @override
  Future<void> markAssessmentUnpublished({required String assessmentId, Transaction? txn}) =>
      ops.markAssessmentUnpublished(localDatabase, assessmentId, txn: txn);

  @override
  Future<void> updateAssessmentOrder({
    required String assessmentId,
    required int orderIndex,
    Transaction? txn,
  }) =>
      ops.updateAssessmentOrder(localDatabase, assessmentId, orderIndex, txn: txn);

  @override
  Future<void> updateQuestionOrder({
    required String questionId,
    required int orderIndex,
    Transaction? txn,
  }) =>
      ops.updateQuestionOrder(localDatabase, questionId, orderIndex, txn: txn);

  @override
  Future<void> clearAllCache() =>
      ops.clearAllCache(localDatabase);
}