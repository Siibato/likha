import 'package:dio/dio.dart';

import 'package:likha/core/constants/api_endpoints.dart';
import 'package:likha/core/network/dio_client.dart';
import 'package:likha/data/models/assessments/assessment_model.dart';
import 'package:likha/data/models/assessments/question_model.dart';

class AssessmentDetailResult {
  final AssessmentModel assessment;
  final List<QuestionModel> questions;

  AssessmentDetailResult({required this.assessment, required this.questions});
}

Future<AssessmentDetailResult> getAssessmentDetail(
  DioClient dioClient, {
  required String assessmentId,
}) async {
  try {
    final response = await dioClient.dio.get(
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
    throw dioClient.handleError(e);
  }
}
