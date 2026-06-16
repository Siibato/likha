import 'package:likha/core/constants/api_endpoints.dart';
import 'package:likha/core/network/dio_client.dart';

Future<void> updateGradeItem(
  DioClient dioClient, {
  required String id,
  required Map<String, dynamic> data,
  String? idempotencyKey,
}) async {
  await dioClient.putVoid(
    ApiEndpoints.gradeItemDetail(id),
    data: data,
    headers: idempotencyKey != null ? {'Idempotency-Key': idempotencyKey} : null,
  );
}
