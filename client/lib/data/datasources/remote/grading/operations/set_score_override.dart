import 'package:likha/core/constants/api_endpoints.dart';
import 'package:likha/core/network/dio_client.dart';

Future<void> setScoreOverride(
  DioClient dioClient, {
  required String scoreId,
  required double overrideScore,
  String? idempotencyKey,
}) async {
  await dioClient.putVoid(
    ApiEndpoints.gradeScoreOverride(scoreId),
    data: {'override_score': overrideScore},
    headers: idempotencyKey != null ? {'Idempotency-Key': idempotencyKey} : null,
  );
}
