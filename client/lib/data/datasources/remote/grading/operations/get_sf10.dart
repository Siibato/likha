import 'package:likha/core/constants/api_endpoints.dart';
import 'package:likha/core/network/dio_client.dart';
import 'package:likha/data/models/grading/sf9_model.dart';

Future<Sf9ResponseModel> getSf10(
  DioClient dioClient, {
  required String classId,
  required String studentId,
}) async {
  return await dioClient.getTyped(ApiEndpoints.sf10(classId, studentId));
}
