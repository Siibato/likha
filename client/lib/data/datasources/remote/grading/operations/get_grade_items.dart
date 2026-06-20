import 'package:dio/dio.dart';

import 'package:likha/core/constants/api_endpoints.dart';
import 'package:likha/core/network/dio_client.dart';
import 'package:likha/data/models/grading/grade_item_model.dart';

Future<List<GradeItemModel>> getGradeItems(
  DioClient dioClient, {
  required String classId,
  required int termNumber,
  String? component,
}) async {
  try {
    final queryParams = <String, dynamic>{'term_number': termNumber};
    if (component != null) queryParams['component'] = component;

    final response = await dioClient.dio.get(
      ApiEndpoints.gradeItems(classId).path,
      queryParameters: queryParams,
    );
    final data = response.data['data'] ?? response.data;
    
    List<dynamic> items;
    if (data is List) {
      items = data;
    } else if (data is Map<String, dynamic>) {
      items = data['items'] as List<dynamic>? ?? [];
    } else {
      items = [];
    }
    
    return items
        .map((e) => GradeItemModel.fromJson(e as Map<String, dynamic>))
        .toList();
  } on DioException catch (e) {
    throw dioClient.handleError(e);
  }
}
