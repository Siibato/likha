import 'package:dio/dio.dart';
import 'package:likha/core/constants/api_constants.dart';
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
      final response = await _dioClient.dio.post(
        ApiConstants.classAssessments(classId),
        data: data,
      );
      final responseData = response.data['data'] ?? response.data;
      return AssessmentModel.fromJson(responseData);
    } on DioException catch (e) {
      throw _dioClient.handleError(e);
    }
  }

  @override
  Future<List<AssessmentModel>> getAssessments({
    required String classId,
  }) async {
    try {
      final response = await _dioClient.dio.get(
        ApiConstants.classAssessments(classId),
      );
      final responseData = response.data['data'] ?? response.data;
      final assessments = (responseData['assessments'] as List<dynamic>)
          .map((e) => AssessmentModel.fromJson(e as Map<String, dynamic>))
          .toList();
      return assessments;
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
        ApiConstants.assessmentDetail(assessmentId),
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
      final response = await _dioClient.dio.put(
        ApiConstants.assessmentDetail(assessmentId),
        data: data,
      );
      final responseData = response.data['data'] ?? response.data;
      return AssessmentModel.fromJson(responseData);
    } on DioException catch (e) {
      throw _dioClient.handleError(e);
    }
  }

  @override
  Future<void> deleteAssessment({required String assessmentId}) async {
    try {
      await _dioClient.dio.delete(
        ApiConstants.assessmentDetail(assessmentId),
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
      final response = await _dioClient.dio.post(
        ApiConstants.assessmentPublish(assessmentId),
      );
      final responseData = response.data['data'] ?? response.data;
      return AssessmentModel.fromJson(responseData);
    } on DioException catch (e) {
      throw _dioClient.handleError(e);
    }
  }

  @override
  Future<AssessmentModel> releaseResults({
    required String assessmentId,
  }) async {
    try {
      final response = await _dioClient.dio.post(
        ApiConstants.assessmentReleaseResults(assessmentId),
      );
      final responseData = response.data['data'] ?? response.data;
      return AssessmentModel.fromJson(responseData);
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
      final response = await _dioClient.dio.post(
        ApiConstants.assessmentQuestions(assessmentId),
        data: {'questions': questions},
      );
      final responseData = response.data['data'] ?? response.data;
      return (responseData as List<dynamic>)
          .map((e) => QuestionModel.fromJson(e as Map<String, dynamic>))
          .toList();
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
      final response = await _dioClient.dio.put(
        ApiConstants.questionDetail(questionId),
        data: data,
      );
      final responseData = response.data['data'] ?? response.data;
      return QuestionModel.fromJson(responseData);
    } on DioException catch (e) {
      throw _dioClient.handleError(e);
    }
  }

  @override
  Future<void> deleteQuestion({required String questionId}) async {
    try {
      await _dioClient.dio.delete(ApiConstants.questionDetail(questionId));
    } on DioException catch (e) {
      throw _dioClient.handleError(e);
    }
  }

  @override
  Future<List<SubmissionSummaryModel>> getSubmissions({
    required String assessmentId,
  }) async {
    try {
      final response = await _dioClient.dio.get(
        ApiConstants.assessmentSubmissions(assessmentId),
      );
      final responseData = response.data['data'] ?? response.data;
      return (responseData['submissions'] as List<dynamic>)
          .map((e) =>
              SubmissionSummaryModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw _dioClient.handleError(e);
    }
  }

  @override
  Future<SubmissionDetailModel> getSubmissionDetail({
    required String submissionId,
  }) async {
    try {
      final response = await _dioClient.dio.get(
        ApiConstants.submissionDetail(submissionId),
      );
      final responseData = response.data['data'] ?? response.data;
      return SubmissionDetailModel.fromJson(responseData);
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
      final response = await _dioClient.dio.put(
        ApiConstants.submissionAnswerOverride(answerId),
        data: {'is_correct': isCorrect},
      );
      final responseData = response.data['data'] ?? response.data;
      return SubmissionAnswerModel.fromJson(responseData);
    } on DioException catch (e) {
      throw _dioClient.handleError(e);
    }
  }

  @override
  Future<AssessmentStatisticsModel> getStatistics({
    required String assessmentId,
  }) async {
    try {
      final response = await _dioClient.dio.get(
        ApiConstants.assessmentStatistics(assessmentId),
      );
      final responseData = response.data['data'] ?? response.data;
      return AssessmentStatisticsModel.fromJson(responseData);
    } on DioException catch (e) {
      throw _dioClient.handleError(e);
    }
  }

  @override
  Future<StartSubmissionResultModel> startAssessment({
    required String assessmentId,
  }) async {
    try {
      final response = await _dioClient.dio.post(
        ApiConstants.assessmentStart(assessmentId),
      );
      final responseData = response.data['data'] ?? response.data;
      return StartSubmissionResultModel.fromJson(responseData);
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
      await _dioClient.dio.put(
        ApiConstants.submissionAnswers(submissionId),
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
      final response = await _dioClient.dio.post(
        ApiConstants.submissionSubmit(submissionId),
      );
      final responseData = response.data['data'] ?? response.data;
      return SubmissionSummaryModel.fromJson(responseData);
    } on DioException catch (e) {
      throw _dioClient.handleError(e);
    }
  }

  @override
  Future<StudentResultModel> getStudentResults({
    required String submissionId,
  }) async {
    try {
      final response = await _dioClient.dio.get(
        ApiConstants.submissionResults(submissionId),
      );
      final responseData = response.data['data'] ?? response.data;
      return StudentResultModel.fromJson(responseData);
    } on DioException catch (e) {
      throw _dioClient.handleError(e);
    }
  }
}
