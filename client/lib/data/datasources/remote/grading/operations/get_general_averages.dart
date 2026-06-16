import 'package:likha/core/constants/api_endpoints.dart';
import 'package:likha/core/network/dio_client.dart';
import 'package:likha/data/models/grading/general_average_model.dart';

Future<GeneralAverageResponseModel> getGeneralAverages(
  DioClient dioClient, {
  required String classId,
}) async {
  return await dioClient.getTyped(ApiEndpoints.generalAverage(classId));
}
