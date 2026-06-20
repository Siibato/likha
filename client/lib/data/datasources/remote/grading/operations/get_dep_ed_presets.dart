import 'package:likha/core/constants/api_endpoints.dart';
import 'package:likha/core/network/dio_client.dart';

Future<Map<String, dynamic>> getDepEdPresets(
  DioClient dioClient,
) async {
  return await dioClient.getTyped(ApiEndpoints.depEdPresets);
}
