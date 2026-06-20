import 'package:dio/dio.dart';

import 'package:likha/core/constants/api_endpoints.dart';
import 'package:likha/core/logging/repo_logger.dart';
import 'package:likha/core/network/dio_client.dart';
import 'package:likha/data/models/assessments/submission_model.dart';

Future<SubmissionSummaryModel> submitAssessment(
  DioClient dioClient, {
  required String submissionId,
  String? idempotencyKey,
}) async {
  RepoLogger.instance.log('submitAssessment() START - submissionId: $submissionId');
  try {
    final result = await dioClient.postTyped<SubmissionSummaryModel>(
      ApiEndpoints.submissionSubmit(submissionId),
      headers: idempotencyKey != null ? {'Idempotency-Key': idempotencyKey} : null,
    );
    RepoLogger.instance.log('submitAssessment() SUCCESS - received: id=${result.id}, isSubmitted=${result.isSubmitted}, submittedAt=${result.submittedAt}');
    return result;
  } on DioException catch (e) {
    RepoLogger.instance.error('submitAssessment() failed', e);
    throw dioClient.handleError(e);
  } catch (e) {
    RepoLogger.instance.error('submitAssessment() unexpected error', e);
    rethrow;
  }
}
