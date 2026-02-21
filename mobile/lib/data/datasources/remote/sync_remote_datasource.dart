import 'package:dio/dio.dart';
import 'package:likha/core/constants/api_endpoints.dart';
import 'package:likha/data/models/sync/conflict_model.dart';
import 'package:likha/data/models/sync/fetch_response_model.dart';
import 'package:likha/data/models/sync/manifest_response_model.dart';
import 'package:likha/data/models/sync/push_response_model.dart';

/// Remote datasource for manifest-driven sync operations
abstract class SyncRemoteDataSource {
  /// Fetch the complete manifest of user's accessible data
  Future<ManifestResponseModel> getManifest();

  /// Fetch paginated full records with cursor support
  ///
  /// Returns paginated records that can be resumed with cursor
  /// if network connection is lost mid-fetch
  Future<FetchResponseModel> fetchRecords({
    required Map<String, List<String>> entities,
    String? cursor,
  });

  /// Push offline mutations to server
  ///
  /// Returns results per operation: success indicators and server IDs
  /// for reconciliation of local_id -> server_id mappings
  Future<PushResponseModel> pushOperations({
    required List<Map<String, dynamic>> operations,
  });

  /// Resolve conflicts detected during sync
  Future<ConflictResolutionResponse> resolveConflict({
    required ConflictResolutionRequest request,
  });
}

/// Implementation of SyncRemoteDataSource using Dio
class SyncRemoteDataSourceImpl implements SyncRemoteDataSource {
  final Dio dio;

  SyncRemoteDataSourceImpl({required this.dio});

  @override
  Future<ManifestResponseModel> getManifest() async {
    try {
      final response = await dio.postUri(
        Uri.parse(ApiEndpoints.syncManifest.path),
        data: {},
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to get manifest');
      }

      return ManifestResponseModel.fromJson(response.data);
    } on DioException catch (e) {
      throw Exception('Network error getting manifest: ${e.message}');
    } catch (e) {
      throw Exception('Error getting manifest: $e');
    }
  }

  @override
  Future<FetchResponseModel> fetchRecords({
    required Map<String, List<String>> entities,
    String? cursor,
  }) async {
    try {
      final data = {
        'entities': entities,
        if (cursor != null) 'cursor': cursor,
      };

      final response = await dio.postUri(
        Uri.parse(ApiEndpoints.syncFetch.path),
        data: data,
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to fetch records');
      }

      return FetchResponseModel.fromJson(response.data);
    } on DioException catch (e) {
      throw Exception('Network error fetching records: ${e.message}');
    } catch (e) {
      throw Exception('Error fetching records: $e');
    }
  }

  @override
  Future<PushResponseModel> pushOperations({
    required List<Map<String, dynamic>> operations,
  }) async {
    try {
      final data = {
        'operations': operations,
      };

      final response = await dio.postUri(
        Uri.parse(ApiEndpoints.syncPush.path),
        data: data,
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to push operations');
      }

      return PushResponseModel.fromJson(response.data);
    } on DioException catch (e) {
      throw Exception('Network error pushing operations: ${e.message}');
    } catch (e) {
      throw Exception('Error pushing operations: $e');
    }
  }

  @override
  Future<ConflictResolutionResponse> resolveConflict({
    required ConflictResolutionRequest request,
  }) async {
    try {
      final response = await dio.postUri(
        Uri.parse(ApiEndpoints.syncResolveConflict.path),
        data: request.toJson(),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to resolve conflict');
      }

      return ConflictResolutionResponse.fromJson(response.data);
    } on DioException catch (e) {
      throw Exception('Network error resolving conflict: ${e.message}');
    } catch (e) {
      throw Exception('Error resolving conflict: $e');
    }
  }
}
