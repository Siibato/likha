import 'package:likha/core/network/dio_client.dart';
import 'package:likha/data/models/assessments/student_assessment_submission_item_model.dart';
import 'package:likha/data/models/assessments/assessment_model.dart';
import 'package:likha/data/models/assessments/question_model.dart';
import 'package:likha/data/models/assessments/statistics_model.dart';
import 'package:likha/data/models/assessments/submission_model.dart';
import 'package:likha/data/datasources/remote/assessments/operations/assessments.dart' as ops;

abstract class AssessmentRemoteDataSource {
  Future<AssessmentModel> createAssessment({
    required String classId,
    required Map<String, dynamic> data,
    String? idempotencyKey,
  });

  Future<List<AssessmentModel>> getAssessments({required String classId});

  Future<AssessmentDetailResult> getAssessmentDetail({
    required String assessmentId,
  });

  Future<AssessmentModel> updateAssessment({
    required String assessmentId,
    required Map<String, dynamic> data,
    String? idempotencyKey,
  });

  Future<void> deleteAssessment({
    required String assessmentId,
    String? idempotencyKey,
  });

  Future<AssessmentModel> publishAssessment({
    required String assessmentId,
    String? idempotencyKey,
  });

  Future<AssessmentModel> unpublishAssessment({
    required String assessmentId,
    String? idempotencyKey,
  });

  Future<AssessmentModel> releaseResults({
    required String assessmentId,
    String? idempotencyKey,
  });

  Future<void> reorderAllAssessments({
    required String classId,
    required List<String> assessmentIds,
    String? idempotencyKey,
  });

  Future<List<QuestionModel>> addQuestions({
    required String assessmentId,
    required List<Map<String, dynamic>> questions,
    String? idempotencyKey,
  });

  Future<QuestionModel> updateQuestion({
    required String questionId,
    required Map<String, dynamic> data,
    String? idempotencyKey,
  });

  Future<void> deleteQuestion({
    required String questionId,
    String? idempotencyKey,
  });

  Future<void> reorderAllQuestions({
    required String assessmentId,
    required List<String> questionIds,
    String? idempotencyKey,
  });

  Future<List<SubmissionSummaryModel>> getSubmissions({
    required String assessmentId,
  });

  Future<SubmissionDetailModel> getSubmissionDetail({
    required String submissionId,
  });

  Future<SubmissionAnswerModel> overrideAnswer({
    required String answerId,
    required bool isCorrect,
    double? points,
    String? idempotencyKey,
  });

  Future<SubmissionAnswerModel> gradeEssayAnswer({
    required String answerId,
    required double points,
    String? idempotencyKey,
  });

  Future<AssessmentStatisticsModel> getStatistics({
    required String assessmentId,
  });

  Future<StartSubmissionResultModel> startAssessment({
    required String assessmentId,
    String? idempotencyKey,
  });

  Future<void> saveAnswers({
    required String submissionId,
    required List<Map<String, dynamic>> answers,
    String? idempotencyKey,
  });

  Future<SubmissionSummaryModel> submitAssessment({
    required String submissionId,
    String? idempotencyKey,
  });

  Future<StudentResultModel> getStudentResults({
    required String submissionId,
  });

  Future<SubmissionSummaryModel?> getStudentSubmission({
    required String assessmentId,
    required String studentId,
  });

  Future<List<StudentAssessmentSubmissionItemModel>> getStudentAssessmentSubmissions({
    required String classId,
    required String studentId,
  });
}

typedef AssessmentDetailResult = ops.AssessmentDetailResult;

class AssessmentRemoteDataSourceImpl implements AssessmentRemoteDataSource {
  final DioClient _dioClient;

  AssessmentRemoteDataSourceImpl(this._dioClient);

  @override
  Future<AssessmentModel> createAssessment({
    required String classId,
    required Map<String, dynamic> data,
    String? idempotencyKey,
  }) =>
      ops.createAssessment(
        _dioClient,
        classId: classId,
        data: data,
        idempotencyKey: idempotencyKey,
      );

  @override
  Future<List<AssessmentModel>> getAssessments({
    required String classId,
  }) =>
      ops.getAssessments(
        _dioClient,
        classId: classId,
      );

  @override
  Future<AssessmentDetailResult> getAssessmentDetail({
    required String assessmentId,
  }) =>
      ops.getAssessmentDetail(
        _dioClient,
        assessmentId: assessmentId,
      );

  @override
  Future<AssessmentModel> updateAssessment({
    required String assessmentId,
    required Map<String, dynamic> data,
    String? idempotencyKey,
  }) =>
      ops.updateAssessment(
        _dioClient,
        assessmentId: assessmentId,
        data: data,
        idempotencyKey: idempotencyKey,
      );

  @override
  Future<void> deleteAssessment({
    required String assessmentId,
    String? idempotencyKey,
  }) =>
      ops.deleteAssessment(
        _dioClient,
        assessmentId: assessmentId,
        idempotencyKey: idempotencyKey,
      );

  @override
  Future<AssessmentModel> publishAssessment({
    required String assessmentId,
    String? idempotencyKey,
  }) =>
      ops.publishAssessment(
        _dioClient,
        assessmentId: assessmentId,
        idempotencyKey: idempotencyKey,
      );

  @override
  Future<AssessmentModel> unpublishAssessment({
    required String assessmentId,
    String? idempotencyKey,
  }) =>
      ops.unpublishAssessment(
        _dioClient,
        assessmentId: assessmentId,
        idempotencyKey: idempotencyKey,
      );

  @override
  Future<AssessmentModel> releaseResults({
    required String assessmentId,
    String? idempotencyKey,
  }) =>
      ops.releaseResults(
        _dioClient,
        assessmentId: assessmentId,
        idempotencyKey: idempotencyKey,
      );

  @override
  Future<void> reorderAllAssessments({
    required String classId,
    required List<String> assessmentIds,
    String? idempotencyKey,
  }) =>
      ops.reorderAllAssessments(
        _dioClient,
        classId: classId,
        assessmentIds: assessmentIds,
        idempotencyKey: idempotencyKey,
      );

  @override
  Future<List<QuestionModel>> addQuestions({
    required String assessmentId,
    required List<Map<String, dynamic>> questions,
    String? idempotencyKey,
  }) =>
      ops.addQuestions(
        _dioClient,
        assessmentId: assessmentId,
        questions: questions,
        idempotencyKey: idempotencyKey,
      );

  @override
  Future<QuestionModel> updateQuestion({
    required String questionId,
    required Map<String, dynamic> data,
    String? idempotencyKey,
  }) =>
      ops.updateQuestion(
        _dioClient,
        questionId: questionId,
        data: data,
        idempotencyKey: idempotencyKey,
      );

  @override
  Future<void> deleteQuestion({
    required String questionId,
    String? idempotencyKey,
  }) =>
      ops.deleteQuestion(
        _dioClient,
        questionId: questionId,
        idempotencyKey: idempotencyKey,
      );

  @override
  Future<void> reorderAllQuestions({
    required String assessmentId,
    required List<String> questionIds,
    String? idempotencyKey,
  }) =>
      ops.reorderAllQuestions(
        _dioClient,
        assessmentId: assessmentId,
        questionIds: questionIds,
        idempotencyKey: idempotencyKey,
      );

  @override
  Future<List<SubmissionSummaryModel>> getSubmissions({
    required String assessmentId,
  }) =>
      ops.getSubmissions(
        _dioClient,
        assessmentId: assessmentId,
      );

  @override
  Future<SubmissionDetailModel> getSubmissionDetail({
    required String submissionId,
  }) =>
      ops.getSubmissionDetail(
        _dioClient,
        submissionId: submissionId,
      );

  @override
  Future<SubmissionAnswerModel> overrideAnswer({
    required String answerId,
    required bool isCorrect,
    double? points,
    String? idempotencyKey,
  }) =>
      ops.overrideAnswer(
        _dioClient,
        answerId: answerId,
        isCorrect: isCorrect,
        points: points,
        idempotencyKey: idempotencyKey,
      );

  @override
  Future<SubmissionAnswerModel> gradeEssayAnswer({
    required String answerId,
    required double points,
    String? idempotencyKey,
  }) =>
      ops.gradeEssayAnswer(
        _dioClient,
        answerId: answerId,
        points: points,
        idempotencyKey: idempotencyKey,
      );

  @override
  Future<AssessmentStatisticsModel> getStatistics({
    required String assessmentId,
  }) =>
      ops.getStatistics(
        _dioClient,
        assessmentId: assessmentId,
      );

  @override
  Future<StartSubmissionResultModel> startAssessment({
    required String assessmentId,
    String? idempotencyKey,
  }) =>
      ops.startAssessment(
        _dioClient,
        assessmentId: assessmentId,
        idempotencyKey: idempotencyKey,
      );

  @override
  Future<void> saveAnswers({
    required String submissionId,
    required List<Map<String, dynamic>> answers,
    String? idempotencyKey,
  }) =>
      ops.saveAnswers(
        _dioClient,
        submissionId: submissionId,
        answers: answers,
        idempotencyKey: idempotencyKey,
      );

  @override
  Future<SubmissionSummaryModel> submitAssessment({
    required String submissionId,
    String? idempotencyKey,
  }) =>
      ops.submitAssessment(
        _dioClient,
        submissionId: submissionId,
        idempotencyKey: idempotencyKey,
      );

  @override
  Future<StudentResultModel> getStudentResults({
    required String submissionId,
  }) =>
      ops.getStudentResults(
        _dioClient,
        submissionId: submissionId,
      );

  @override
  Future<SubmissionSummaryModel?> getStudentSubmission({
    required String assessmentId,
    required String studentId,
  }) =>
      ops.getStudentSubmission(
        _dioClient,
        assessmentId: assessmentId,
        studentId: studentId,
      );

  @override
  Future<List<StudentAssessmentSubmissionItemModel>> getStudentAssessmentSubmissions({
    required String classId,
    required String studentId,
  }) =>
      ops.getStudentAssessmentSubmissions(
        _dioClient,
        classId: classId,
        studentId: studentId,
      );
}
