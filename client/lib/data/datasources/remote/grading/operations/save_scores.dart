import 'dart:convert';

import 'package:likha/core/constants/api_endpoints.dart';
import 'package:likha/core/network/dio_client.dart';
import 'package:likha/core/logging/repo_logger.dart';

Future<void> saveScores(
  DioClient dioClient, {
  required String gradeItemId,
  required List<Map<String, dynamic>> scores,
  String? idempotencyKey,
}) async {
  final body = {'scores': scores};
  RepoLogger.instance.log(
    'saveScores PUT ${ApiEndpoints.gradeItemScores(gradeItemId).path} | '
    'idempotencyKey=${idempotencyKey?.substring(0, 8)} | '
    'scoresCount=${scores.length} | body=${jsonEncode(body)}',
  );
  await dioClient.putVoid(
    ApiEndpoints.gradeItemScores(gradeItemId),
    data: body,
    headers: idempotencyKey != null ? {'Idempotency-Key': idempotencyKey} : null,
  );
}
