import 'package:dio/dio.dart';

import 'package:likha/core/network/dio_client.dart';
import 'package:likha/data/models/grading/grade_item_model.dart';

Future<GradeItemModel> createGradeItem(
  DioClient dioClient, {
  required String classId,
  required Map<String, dynamic> data,
}) async {
  try {
    final response = await dioClient.dio.post(
      '${dioClient.dio.options.baseUrl}/classes/$classId/grade-items',
      data: data,
    );
    final responseData = response.data['data'] ?? response.data;
    return GradeItemModel.fromJson(responseData as Map<String, dynamic>);
  } on DioException catch (e) {
    throw dioClient.handleError(e);
  }
}
