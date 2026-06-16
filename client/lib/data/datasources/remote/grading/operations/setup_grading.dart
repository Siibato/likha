import 'package:likha/core/constants/api_endpoints.dart';
import 'package:likha/core/network/dio_client.dart';

Future<void> setupGrading(
  DioClient dioClient, {
  required String classId,
  required Map<String, dynamic> data,
  String? idempotencyKey,
}) async {
  await dioClient.postVoid(
    ApiEndpoints.gradingConfigSetup(classId),
    data: data,
    headers: idempotencyKey != null ? {'Idempotency-Key': idempotencyKey} : null,
  );
}
