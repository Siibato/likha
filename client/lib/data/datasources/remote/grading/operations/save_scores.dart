import 'package:likha/core/constants/api_endpoints.dart';
import 'package:likha/core/network/dio_client.dart';

Future<void> saveScores(
  DioClient dioClient, {
  required String gradeItemId,
  required List<Map<String, dynamic>> scores,
  String? idempotencyKey,
}) async {
  await dioClient.putVoid(
    ApiEndpoints.gradeItemScores(gradeItemId),
    data: {'scores': scores},
    headers: idempotencyKey != null ? {'Idempotency-Key': idempotencyKey} : null,
  );
}
