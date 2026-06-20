import 'package:likha/core/constants/api_endpoints.dart';
import 'package:likha/core/network/dio_client.dart';
import 'package:likha/data/models/tos/tos_model.dart';

Future<TosModel> createTos(
  DioClient dioClient, {
  required String classId,
  required Map<String, dynamic> data,
  String? idempotencyKey,
}) async {
  return dioClient.postTyped(
    ApiEndpoints.tosCreate(classId),
    data: data,
    headers: idempotencyKey != null ? {'Idempotency-Key': idempotencyKey} : null,
  );
}
