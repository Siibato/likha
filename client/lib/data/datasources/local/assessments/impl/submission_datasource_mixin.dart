import 'package:likha/data/models/assessments/submission_model.dart';
import '../assessment_local_datasource_base.dart';
import 'operations/submission/save_answers_locally.dart';
import 'operations/submission/cache_start_submission_result.dart';
import 'operations/submission/start_assessment_locally.dart';
import 'operations/submission/get_cached_start_result.dart';
import 'operations/submission/get_cached_student_submission.dart';
import 'operations/submission/submit_assessment_locally.dart';
import 'operations/submission/get_cached_submission_detail.dart';
import 'operations/submission/cache_submission_detail.dart';
import 'operations/submission/get_cached_submissions.dart';
import 'operations/submission/get_cached_submission_count.dart';
import 'operations/submission/has_student_submitted_assessment.dart';
import 'operations/submission/cache_submissions.dart';
import 'operations/submission/override_answer_locally.dart';
import 'operations/submission/grade_essay_locally.dart';

mixin SubmissionDataSourceMixin on AssessmentLocalDataSourceBase {
  @override
  Future<void> saveAnswersLocally({
    required String submissionId,
    required String answersJson,
  }) async {
    return saveAnswersLocallyOp(localDatabase, syncQueue, submissionId, answersJson);
  }

  @override
  Future<void> cacheStartSubmissionResult({
    required String submissionId,
    required String assessmentId,
    required String studentId,
    required String studentName,
    required String studentUsername,
    required DateTime startedAt,
  }) async {
    return cacheStartSubmissionResultOp(localDatabase, submissionId, assessmentId, studentId, studentName, studentUsername, startedAt);
  }

  @override
  Future<String> startAssessmentLocally({
    required String assessmentId,
    required String studentId,
    required String studentName,
    required String studentUsername,
  }) async {
    return startAssessmentLocallyOp(localDatabase, syncQueue, assessmentId, studentId, studentName, studentUsername);
  }

  @override
  Future<StartSubmissionResultModel?> getCachedStartResult(String submissionId) async {
    return getCachedStartResultOp(localDatabase, submissionId);
  }

  @override
  Future<SubmissionSummaryModel?> getCachedStudentSubmission(
    String assessmentId,
    String studentId,
  ) async {
    return getCachedStudentSubmissionOp(localDatabase, assessmentId, studentId);
  }

  @override
  Future<void> submitAssessmentLocally({
    required String submissionId,
    required String assessmentId,
  }) async {
    return submitAssessmentLocallyOp(localDatabase, syncQueue, submissionId, assessmentId);
  }

  @override
  Future<SubmissionDetailModel?> getCachedSubmissionDetail(String submissionId) async {
    return getCachedSubmissionDetailOp(localDatabase, submissionId);
  }

  @override
  Future<void> cacheSubmissionDetail(SubmissionDetailModel submission) async {
    return cacheSubmissionDetailOp(localDatabase, submission);
  }

  @override
  Future<List<SubmissionSummaryModel>> getCachedSubmissions(String assessmentId) async {
    return getCachedSubmissionsOp(localDatabase, assessmentId);
  }

  @override
  Future<int> getCachedSubmissionCount(String assessmentId) async {
    return getCachedSubmissionCountOp(localDatabase, assessmentId);
  }

  @override
  Future<bool?> hasStudentSubmittedAssessment(String assessmentId, String studentId) async {
    return hasStudentSubmittedAssessmentOp(localDatabase, assessmentId, studentId);
  }

  @override
  Future<void> cacheSubmissions(String assessmentId, List<SubmissionSummaryModel> submissions) async {
    return cacheSubmissionsOp(localDatabase, assessmentId, submissions);
  }

  @override
  Future<void> overrideAnswerLocally({
    required String answerId,
    required bool isCorrect,
    double? points,
  }) async {
    return overrideAnswerLocallyOp(localDatabase, syncQueue, answerId, isCorrect, points);
  }

  @override
  Future<void> gradeEssayLocally({
    required String answerId,
    required double points,
  }) async {
    return gradeEssayLocallyOp(localDatabase, syncQueue, answerId, points);
  }
}
