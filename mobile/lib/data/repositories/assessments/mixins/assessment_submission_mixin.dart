import 'package:likha/core/utils/typedef.dart';
import 'package:likha/domain/assessments/entities/assessment_statistics.dart';
import 'package:likha/domain/assessments/entities/submission.dart';
import 'package:likha/data/repositories/assessments/assessment_repository_base.dart';
import 'package:likha/data/repositories/assessments/mixins/operations/submission/get_submissions.dart'
    as get_submissions_op;
import 'package:likha/data/repositories/assessments/mixins/operations/submission/get_submission_detail.dart'
    as get_submission_detail_op;
import 'package:likha/data/repositories/assessments/mixins/operations/submission/override_answer.dart'
    as override_answer_op;
import 'package:likha/data/repositories/assessments/mixins/operations/submission/grade_essay_answer.dart'
    as grade_essay_answer_op;
import 'package:likha/data/repositories/assessments/mixins/operations/submission/get_statistics.dart'
    as get_statistics_op;
import 'package:likha/data/repositories/assessments/mixins/operations/submission/get_student_submission.dart'
    as get_student_submission_op;
import 'package:likha/data/repositories/assessments/mixins/operations/submission/start_assessment.dart'
    as start_assessment_op;
import 'package:likha/data/repositories/assessments/mixins/operations/submission/save_answers.dart'
    as save_answers_op;
import 'package:likha/data/repositories/assessments/mixins/operations/submission/submit_assessment.dart'
    as submit_assessment_op;
import 'package:likha/data/repositories/assessments/mixins/operations/submission/get_student_results.dart'
    as get_student_results_op;

mixin AssessmentSubmissionMixin on AssessmentRepositoryBase {
  @override
  ResultFuture<List<SubmissionSummary>> getSubmissions({
    required String assessmentId,
  }) =>
      get_submissions_op.getSubmissions(this, assessmentId: assessmentId);

  @override
  ResultFuture<SubmissionDetail> getSubmissionDetail({
    required String submissionId,
  }) =>
      get_submission_detail_op.getSubmissionDetail(this, submissionId: submissionId);

  @override
  ResultFuture<SubmissionAnswer> overrideAnswer({
    required String answerId,
    required bool isCorrect,
    double? points,
  }) =>
      override_answer_op.overrideAnswer(
        this,
        answerId: answerId,
        isCorrect: isCorrect,
        points: points,
      );

  @override
  ResultFuture<SubmissionAnswer> gradeEssayAnswer({
    required String answerId,
    required double points,
  }) =>
      grade_essay_answer_op.gradeEssayAnswer(
        this,
        answerId: answerId,
        points: points,
      );

  @override
  ResultFuture<AssessmentStatistics> getStatistics({
    required String assessmentId,
  }) =>
      get_statistics_op.getStatistics(this, assessmentId: assessmentId);

  @override
  ResultFuture<SubmissionSummary?> getStudentSubmission({
    required String assessmentId,
    required String studentId,
  }) =>
      get_student_submission_op.getStudentSubmission(
        this,
        assessmentId: assessmentId,
        studentId: studentId,
      );

  @override
  ResultFuture<StartSubmissionResult> startAssessment({
    required String assessmentId,
    required String studentId,
    required String studentName,
    required String studentUsername,
  }) =>
      start_assessment_op.startAssessment(
        this,
        assessmentId: assessmentId,
        studentId: studentId,
        studentName: studentName,
        studentUsername: studentUsername,
      );

  @override
  ResultVoid saveAnswers({
    required String submissionId,
    required List<Map<String, dynamic>> answers,
  }) =>
      save_answers_op.saveAnswers(
        this,
        submissionId: submissionId,
        answers: answers,
      );

  @override
  ResultFuture<SubmissionSummary> submitAssessment({
    required String submissionId,
  }) =>
      submit_assessment_op.submitAssessment(this, submissionId: submissionId);

  @override
  ResultFuture<StudentResult> getStudentResults({
    required String submissionId,
  }) =>
      get_student_results_op.getStudentResults(this, submissionId: submissionId);
}