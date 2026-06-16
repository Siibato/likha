import 'package:likha/core/constants/api_endpoints.dart';
import 'package:likha/core/network/dio_client.dart';

Future<void> deleteGradeItem(
  DioClient dioClient, {
  required String id,
  String? idempotencyKey,
}) async {
  await dioClient.deleteTyped(
    ApiEndpoints.gradeItemDetail(id),
    headers: idempotencyKey != null ? {'Idempotency-Key': idempotencyKey} : null,
  );
}
