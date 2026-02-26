import 'package:dio/dio.dart';
import 'package:likha/core/constants/api_endpoints.dart';
import 'package:likha/core/errors/exceptions.dart';
import 'package:likha/core/network/dio_client.dart';
import 'package:likha/core/sync/change_log_model.dart';

abstract class ChangeLogRemoteDataSource {
  Future<ChangesResponse> fetchChangesSince({
    required int sinceSequence,
    int limit = 500,
  });

  Future<List<ChangeLogEntry>> getEntityChanges({
    required String entityType,
    required String entityId,
    String? since,
    int limit = 500,
  });
}

class ChangeLogRemoteDataSourceImpl implements ChangeLogRemoteDataSource {
  final DioClient _dioClient;

  ChangeLogRemoteDataSourceImpl(this._dioClient);

  @override
  Future<ChangesResponse> fetchChangesSince({
    required int sinceSequence,
    int limit = 500,
  }) async {
    try {
      final response = await _dioClient.dio.get(
        ApiEndpoints.changes.path,
        queryParameters: {
          'since_sequence': sinceSequence,
          'limit': limit,
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data['data'] ?? response.data;
        return ChangesResponse.fromJson(data);
      } else {
        throw ServerException(
          response.data['message'] ?? 'Failed to fetch changes',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      throw ServerException(
        e.message ?? 'Network error',
        statusCode: e.response?.statusCode,
      );
    } catch (e) {
      throw ServerException('Error fetching changes: $e');
    }
  }

  @override
  Future<List<ChangeLogEntry>> getEntityChanges({
    required String entityType,
    required String entityId,
    String? since,
    int limit = 500,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'limit': limit,
      };
      if (since != null) {
        queryParams['since'] = since;
      }

      final response = await _dioClient.dio.get(
        '/api/v1/entities/$entityType/$entityId/changes',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data['data'] ?? response.data;
        final changesData = data['changes'] as List? ?? [];
        return changesData
            .map((e) => ChangeLogEntry.fromJson(e as Map<String, dynamic>))
            .toList();
      } else {
        throw ServerException(
          response.data['message'] ?? 'Failed to fetch entity changes',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      throw ServerException(
        e.message ?? 'Network error',
        statusCode: e.response?.statusCode,
      );
    } catch (e) {
      throw ServerException('Error fetching entity changes: $e');
    }
  }
}
