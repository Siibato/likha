import 'package:likha/core/constants/api_endpoints.dart';
import 'package:likha/core/network/dio_client.dart';

Future<void> computeGrades(
  DioClient dioClient, {
  required String classId,
  required int termNumber,
}) async {
  await dioClient.postVoid(
    ApiEndpoints.classGradesCompute(classId),
    queryParameters: {'term_number': termNumber},
  );
}
