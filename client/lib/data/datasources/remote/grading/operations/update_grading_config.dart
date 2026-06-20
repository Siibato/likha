import 'package:likha/core/constants/api_endpoints.dart';
import 'package:likha/core/network/dio_client.dart';

Future<void> updateGradingConfig(
  DioClient dioClient, {
  required String classId,
  required List<Map<String, dynamic>> configs,
  String? idempotencyKey,
}) async {
  await dioClient.putVoid(
    ApiEndpoints.gradingConfig(classId),
    data: {'configs': configs},
    headers: idempotencyKey != null ? {'Idempotency-Key': idempotencyKey} : null,
  );
}
