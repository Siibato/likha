import 'package:dio/dio.dart';

import 'package:likha/core/constants/api_endpoints.dart';
import 'package:likha/core/logging/repo_logger.dart';
import 'package:likha/core/network/dio_client.dart';
import 'package:likha/data/models/auth/user_model.dart';

Future<List<UserModel>> getAllAccounts(
  DioClient dioClient,
) async {
  RepoLogger.instance.log('getAllAccounts: Calling remote API');
  try {
    final result = await dioClient.getTyped(ApiEndpoints.accountsList);
    RepoLogger.instance.log('getAllAccounts: Remote API returned ${result.length} accounts');
    return result;
  } on DioException catch (e) {
    RepoLogger.instance.error('getAllAccounts: DioException - ${e.message}', e);
    throw dioClient.handleError(e);
  }
}
