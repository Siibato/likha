import 'package:likha/core/constants/api_endpoints.dart';
import 'package:likha/core/network/dio_client.dart';

Future<void> clearScoreOverride(
  DioClient dioClient, {
  required String scoreId,
  String? idempotencyKey,
}) async {
  await dioClient.deleteTyped(
    ApiEndpoints.gradeScoreOverride(scoreId),
    headers: idempotencyKey != null ? {'Idempotency-Key': idempotencyKey} : null,
  );
}
