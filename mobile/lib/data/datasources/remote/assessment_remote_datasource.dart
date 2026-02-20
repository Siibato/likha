import 'package:dio/dio.dart';
import 'package:likha/core/constants/api_endpoints.dart';
import 'package:likha/core/network/dio_client.dart';
import 'package:likha/domain/assessments/data/models/assessment_model.dart';
import 'package:likha/domain/assessments/data/models/question_model.dart';
import 'package:likha/domain/assessments/data/models/statistics_model.dart';
import 'package:likha/domain/assessments/data/models/submission_model.dart';

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

  Future<AssessmentModel> releaseResults({required String assessmentId});

  Future<List<QuestionModel>> addQuestions({
    required String assessmentId,
    required List<Map<String, dynamic>> questions,
  });

  Future<QuestionModel> updateQuestion({
    required String questionId,
    required Map<String, dynamic> data,
  });

  Future<void> deleteQuestion({required String questionId});

  Future<List<SubmissionSummaryModel>> getSubmissions({
    required String assessmentId,
  });

  Future<SubmissionDetailModel> getSubmissionDetail({
    required String submissionId,
  });

  Future<SubmissionAnswerModel> overrideAnswer({
    required String answerId,
    required bool isCorrect,
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
}

class AssessmentDetailResult {
  final AssessmentModel assessment;
  final List<QuestionModel> questions;

  AssessmentDetailResult({required this.assessment, required this.questions});
}

class AssessmentRemoteDataSourceImpl implements AssessmentRemoteDataSource {
  final DioClient _dioClient;

  AssessmentRemoteDataSourceImpl(this._dioClient);

  @override
  Future<AssessmentModel> createAssessment({
    required String classId,
    required Map<String, dynamic> data,
  }) async {
    try {
      return await _dioClient.postTyped(
        ApiEndpoints.classAssessments(classId),
        data: data,
      );
    } on DioException catch (e) {
      throw _dioClient.handleError(e);
    }
  }

  @override
  Future<List<AssessmentModel>> getAssessments({
    required String classId,
  }) async {
    try {
      return await _dioClient.getTyped(
        ApiEndpoints.classAssessmentsList(classId),
      );
    } on DioException catch (e) {
      throw _dioClient.handleError(e);
    }
  }

  @override
  Future<AssessmentDetailResult> getAssessmentDetail({
    required String assessmentId,
  }) async {
    try {
      final response = await _dioClient.dio.get(
        ApiEndpoints.assessmentDetail(assessmentId).path,
      );
      final responseData = response.data['data'] ?? response.data;
      final assessment = AssessmentModel.fromJson(responseData);
      final questions = (responseData['questions'] as List<dynamic>?)
              ?.map((e) => QuestionModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [];
      return AssessmentDetailResult(assessment: assessment, questions: questions);
    } on DioException catch (e) {
      throw _dioClient.handleError(e);
    }
  }

  @override
  Future<AssessmentModel> updateAssessment({
    required String assessmentId,
    required Map<String, dynamic> data,
  }) async {
    try {
      return await _dioClient.putTyped(
        ApiEndpoints.assessmentDetail(assessmentId),
        data: data,
      );
    } on DioException catch (e) {
      throw _dioClient.handleError(e);
    }
  }

  @override
  Future<void> deleteAssessment({required String assessmentId}) async {
    try {
      await _dioClient.deleteTyped(
        ApiEndpoints.assessmentDetail(assessmentId),
      );
    } on DioException catch (e) {
      throw _dioClient.handleError(e);
    }
  }

  @override
  Future<AssessmentModel> publishAssessment({
    required String assessmentId,
  }) async {
    try {
      return await _dioClient.postTyped(
        ApiEndpoints.assessmentPublish(assessmentId),
      );
    } on DioException catch (e) {
      throw _dioClient.handleError(e);
    }
  }

  @override
  Future<AssessmentModel> releaseResults({
    required String assessmentId,
  }) async {
    try {
      return await _dioClient.postTyped(
        ApiEndpoints.assessmentReleaseResults(assessmentId),
      );
    } on DioException catch (e) {
      throw _dioClient.handleError(e);
    }
  }

  @override
  Future<List<QuestionModel>> addQuestions({
    required String assessmentId,
    required List<Map<String, dynamic>> questions,
  }) async {
    try {
      return await _dioClient.postTyped(
        ApiEndpoints.assessmentQuestions(assessmentId),
        data: {'questions': questions},
      );
    } on DioException catch (e) {
      throw _dioClient.handleError(e);
    }
  }

  @override
  Future<QuestionModel> updateQuestion({
    required String questionId,
    required Map<String, dynamic> data,
  }) async {
    try {
      return await _dioClient.putTyped(
        ApiEndpoints.questionDetail(questionId),
        data: data,
      );
    } on DioException catch (e) {
      throw _dioClient.handleError(e);
    }
  }

  @override
  Future<void> deleteQuestion({required String questionId}) async {
    try {
      await _dioClient.deleteTyped(ApiEndpoints.questionDetail(questionId));
    } on DioException catch (e) {
      throw _dioClient.handleError(e);
    }
  }

  @override
  Future<List<SubmissionSummaryModel>> getSubmissions({
    required String assessmentId,
  }) async {
    try {
      return await _dioClient.getTyped(
        ApiEndpoints.assessmentSubmissions(assessmentId),
      );
    } on DioException catch (e) {
      throw _dioClient.handleError(e);
    }
  }

  @override
  Future<SubmissionDetailModel> getSubmissionDetail({
    required String submissionId,
  }) async {
    try {
      return await _dioClient.getTyped(
        ApiEndpoints.submissionDetail(submissionId),
      );
    } on DioException catch (e) {
      throw _dioClient.handleError(e);
    }
  }

  @override
  Future<SubmissionAnswerModel> overrideAnswer({
    required String answerId,
    required bool isCorrect,
  }) async {
    try {
      return await _dioClient.putTyped(
        ApiEndpoints.submissionAnswerOverride(answerId),
        data: {'is_correct': isCorrect},
      );
    } on DioException catch (e) {
      throw _dioClient.handleError(e);
    }
  }

  @override
  Future<AssessmentStatisticsModel> getStatistics({
    required String assessmentId,
  }) async {
    try {
      return await _dioClient.getTyped(
        ApiEndpoints.assessmentStatistics(assessmentId),
      );
    } on DioException catch (e) {
      throw _dioClient.handleError(e);
    }
  }

  @override
  Future<StartSubmissionResultModel> startAssessment({
    required String assessmentId,
  }) async {
    try {
      return await _dioClient.postTyped(
        ApiEndpoints.assessmentStart(assessmentId),
      );
    } on DioException catch (e) {
      throw _dioClient.handleError(e);
    }
  }

  @override
  Future<void> saveAnswers({
    required String submissionId,
    required List<Map<String, dynamic>> answers,
  }) async {
    try {
      await _dioClient.putTyped(
        ApiEndpoints.submissionAnswers(submissionId),
        data: {'answers': answers},
      );
    } on DioException catch (e) {
      throw _dioClient.handleError(e);
    }
  }

  @override
  Future<SubmissionSummaryModel> submitAssessment({
    required String submissionId,
  }) async {
    try {
      return await _dioClient.postTyped(
        ApiEndpoints.submissionSubmit(submissionId),
      );
    } on DioException catch (e) {
      throw _dioClient.handleError(e);
    }
  }

  @override
  Future<StudentResultModel> getStudentResults({
    required String submissionId,
  }) async {
    try {
      return await _dioClient.getTyped(
        ApiEndpoints.submissionResults(submissionId),
      );
    } on DioException catch (e) {
      throw _dioClient.handleError(e);
    }
  }
}
