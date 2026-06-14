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
  });

  Future<List<AssessmentModel>> getAssessments({required String classId});

  Future<AssessmentDetailResult> getAssessmentDetail({
    required String assessmentId,
  });

  Future<AssessmentModel> updateAssessment({
    required String assessmentId,
    required Map<String, dynamic> data,
  });

  Future<void> deleteAssessment({required String assessmentId});

  Future<AssessmentModel> publishAssessment({required String assessmentId});

  Future<AssessmentModel> unpublishAssessment({required String assessmentId});

  Future<AssessmentModel> releaseResults({required String assessmentId});

  Future<void> reorderAllAssessments({
    required String classId,
    required List<String> assessmentIds,
  });

  Future<List<QuestionModel>> addQuestions({
    required String assessmentId,
    required List<Map<String, dynamic>> questions,
  });

  Future<QuestionModel> updateQuestion({
    required String questionId,
    required Map<String, dynamic> data,
  });

  Future<void> deleteQuestion({required String questionId});

  Future<void> reorderAllQuestions({
    required String assessmentId,
    required List<String> questionIds,
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
  });

  Future<SubmissionAnswerModel> gradeEssayAnswer({
    required String answerId,
    required double points,
  });

  Future<AssessmentStatisticsModel> getStatistics({
    required String assessmentId,
  });

  Future<StartSubmissionResultModel> startAssessment({
    required String assessmentId,
  });

  Future<void> saveAnswers({
    required String submissionId,
    required List<Map<String, dynamic>> answers,
  });

  Future<SubmissionSummaryModel> submitAssessment({
    required String submissionId,
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
  }) =>
      ops.createAssessment(
        _dioClient,
        classId: classId,
        data: data,
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
  }) =>
      ops.updateAssessment(
        _dioClient,
        assessmentId: assessmentId,
        data: data,
      );

  @override
  Future<void> deleteAssessment({required String assessmentId}) =>
      ops.deleteAssessment(
        _dioClient,
        assessmentId: assessmentId,
      );

  @override
  Future<AssessmentModel> publishAssessment({
    required String assessmentId,
  }) =>
      ops.publishAssessment(
        _dioClient,
        assessmentId: assessmentId,
      );

  @override
  Future<AssessmentModel> unpublishAssessment({
    required String assessmentId,
  }) =>
      ops.unpublishAssessment(
        _dioClient,
        assessmentId: assessmentId,
      );

  @override
  Future<AssessmentModel> releaseResults({
    required String assessmentId,
  }) =>
      ops.releaseResults(
        _dioClient,
        assessmentId: assessmentId,
      );

  @override
  Future<void> reorderAllAssessments({
    required String classId,
    required List<String> assessmentIds,
  }) =>
      ops.reorderAllAssessments(
        _dioClient,
        classId: classId,
        assessmentIds: assessmentIds,
      );

  @override
  Future<List<QuestionModel>> addQuestions({
    required String assessmentId,
    required List<Map<String, dynamic>> questions,
  }) =>
      ops.addQuestions(
        _dioClient,
        assessmentId: assessmentId,
        questions: questions,
      );

  @override
  Future<QuestionModel> updateQuestion({
    required String questionId,
    required Map<String, dynamic> data,
  }) =>
      ops.updateQuestion(
        _dioClient,
        questionId: questionId,
        data: data,
      );

  @override
  Future<void> deleteQuestion({required String questionId}) =>
      ops.deleteQuestion(
        _dioClient,
        questionId: questionId,
      );

  @override
  Future<void> reorderAllQuestions({
    required String assessmentId,
    required List<String> questionIds,
  }) =>
      ops.reorderAllQuestions(
        _dioClient,
        assessmentId: assessmentId,
        questionIds: questionIds,
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
  }) =>
      ops.overrideAnswer(
        _dioClient,
        answerId: answerId,
        isCorrect: isCorrect,
        points: points,
      );

  @override
  Future<SubmissionAnswerModel> gradeEssayAnswer({
    required String answerId,
    required double points,
  }) =>
      ops.gradeEssayAnswer(
        _dioClient,
        answerId: answerId,
        points: points,
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
  }) =>
      ops.startAssessment(
        _dioClient,
        assessmentId: assessmentId,
      );

  @override
  Future<void> saveAnswers({
    required String submissionId,
    required List<Map<String, dynamic>> answers,
  }) =>
      ops.saveAnswers(
        _dioClient,
        submissionId: submissionId,
        answers: answers,
      );

  @override
  Future<SubmissionSummaryModel> submitAssessment({
    required String submissionId,
  }) =>
      ops.submitAssessment(
        _dioClient,
        submissionId: submissionId,
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
