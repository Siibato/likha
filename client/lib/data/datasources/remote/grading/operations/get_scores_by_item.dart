import 'package:dio/dio.dart';

import 'package:likha/core/constants/api_endpoints.dart';
import 'package:likha/core/network/dio_client.dart';
import 'package:likha/data/models/grading/grade_score_model.dart';

Future<List<GradeScoreModel>> getScoresByItem(
  DioClient dioClient, {
  required String gradeItemId,
}) async {
  try {
    final response = await dioClient.dio.get(
      ApiEndpoints.gradeItemScores(gradeItemId).path,
    );
    final data = response.data['data'] ?? response.data;
    
    List<dynamic> scores;
    if (data is List) {
      scores = data;
    } else if (data is Map<String, dynamic>) {
      scores = data['scores'] as List<dynamic>? ?? [];
    } else {
      scores = [];
    }
    
    return scores
        .map((e) => GradeScoreModel.fromJson(e as Map<String, dynamic>))
        .toList();
  } on DioException catch (e) {
    throw dioClient.handleError(e);
  }
}
