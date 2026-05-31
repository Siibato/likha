import 'package:dio/dio.dart';

import 'package:likha/core/constants/api_endpoints.dart';
import 'package:likha/core/logging/repo_logger.dart';
import 'package:likha/core/network/dio_client.dart';
import 'package:likha/data/models/assessments/submission_model.dart';

Future<StartSubmissionResultModel> startAssessment(
  DioClient dioClient, {
  required String assessmentId,
}) async {
  RepoLogger.instance.log('startAssessment() START - assessmentId: $assessmentId');
  try {
    final result = await dioClient.postTyped(
      ApiEndpoints.assessmentStart(assessmentId),
    );
    RepoLogger.instance.log('startAssessment() SUCCESS - submissionId: ${result.submissionId}, startedAt: ${result.startedAt}, questionCount: ${result.questions.length}');
    return result;
  } on DioException catch (e) {
    RepoLogger.instance.error('startAssessment() failed', e);
    throw dioClient.handleError(e);
  }
}
