import 'package:likha/core/constants/api_endpoints.dart';
import 'package:likha/core/network/dio_client.dart';
import 'package:likha/data/models/tos/tos_model.dart';

Future<CompetencyModel> addCompetency(
  DioClient dioClient, {
  required String tosId,
  required Map<String, dynamic> data,
  String? idempotencyKey,
}) async {
  return dioClient.postTyped(
    ApiEndpoints.tosCompetencyCreate(tosId),
    data: data,
    headers: idempotencyKey != null ? {'Idempotency-Key': idempotencyKey} : null,
  );
}
