import 'package:dio/dio.dart';

import 'package:likha/core/constants/api_endpoints.dart';
import 'package:likha/core/logging/repo_logger.dart';
import 'package:likha/core/network/dio_client.dart';
import 'package:likha/data/models/assessments/submission_model.dart';

Future<SubmissionDetailModel> getSubmissionDetail(
  DioClient dioClient, {
  required String submissionId,
}) async {
  try {
    RepoLogger.instance.log('remote.getSubmissionDetail: fetching $submissionId');
    final result = await dioClient.getTyped(
      ApiEndpoints.submissionDetail(submissionId),
    );
    RepoLogger.instance.log('remote.getSubmissionDetail: fetched $submissionId with ${result.answers.length} answers');
    return result;
  } on DioException catch (e) {
    RepoLogger.instance.log('remote.getSubmissionDetail: FAILED for $submissionId: ${e.message}');
    throw dioClient.handleError(e);
  }
}
