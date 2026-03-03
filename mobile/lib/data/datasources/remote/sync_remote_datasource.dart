import 'package:dio/dio.dart';
import 'package:likha/core/constants/api_endpoints.dart';
import 'package:likha/core/network/dio_client.dart';
import 'package:likha/data/models/sync/conflict_model.dart';
import 'package:likha/data/models/sync/push_response_model.dart';

/// Remote datasource for offline sync operations
abstract class SyncRemoteDataSource {
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

  /// Fetch full sync data on first login
  Future<Map<String, dynamic>> fullSync({required String deviceId});

  /// Fetch delta sync data on app restart
  Future<Map<String, dynamic>> deltaSync({
    required String deviceId,
    required String lastSyncAt,
    String? dataExpiryAt,
  });

  /// Upload a file for a submission (assignment or assessment)
  Future<void> uploadSubmissionFile({
    required String submissionId,
    required String localPath,
    required String fileName,
  });

  /// Upload a file for learning material
  Future<void> uploadMaterialFile({
    required String materialId,
    required String localPath,
    required String fileName,
  });
}

/// Implementation of SyncRemoteDataSource using Dio
class SyncRemoteDataSourceImpl implements SyncRemoteDataSource {
  final DioClient dioClient;

  SyncRemoteDataSourceImpl({required this.dioClient});

  Dio get _dio => dioClient.dio;

  @override
  Future<PushResponseModel> pushOperations({
    required List<Map<String, dynamic>> operations,
  }) async {
    try {
      final data = {
        'operations': operations,
      };

      final response = await _dio.postUri(
        Uri.parse(ApiEndpoints.syncPush.path),
        data: data,
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to push operations');
      }

      // Extract the 'data' wrapper from the API response
      final responseData = response.data as Map<String, dynamic>;
      final innerData = responseData['data'] as Map<String, dynamic>? ?? {};
      return PushResponseModel.fromJson(innerData);
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
      final response = await _dio.postUri(
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

  @override
  Future<void> uploadSubmissionFile({
    required String submissionId,
    required String localPath,
    required String fileName,
  }) async {
    try {
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(localPath, filename: fileName),
      });
      await _dio.post(
        ApiEndpoints.assignmentSubmissionUpload(submissionId).path,
        data: formData,
      );
    } on DioException catch (e) {
      throw Exception('Network error uploading submission file: ${e.message}');
    } catch (e) {
      throw Exception('Error uploading submission file: $e');
    }
  }

  @override
  Future<void> uploadMaterialFile({
    required String materialId,
    required String localPath,
    required String fileName,
  }) async {
    try {
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(localPath, filename: fileName),
      });
      await _dio.post(
        ApiEndpoints.materialUploadFile(materialId).path,
        data: formData,
      );
    } on DioException catch (e) {
      throw Exception('Network error uploading material file: ${e.message}');
    } catch (e) {
      throw Exception('Error uploading material file: $e');
    }
  }

  @override
  Future<Map<String, dynamic>> fullSync({required String deviceId}) async {
    try {
      final response = await _dio.postUri(
        Uri.parse(ApiEndpoints.syncFull.path),
        data: {'device_id': deviceId},
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to fetch full sync');
      }

      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw Exception('Network error fetching full sync: ${e.message}');
    } catch (e) {
      throw Exception('Error fetching full sync: $e');
    }
  }

  @override
  Future<Map<String, dynamic>> deltaSync({
    required String deviceId,
    required String lastSyncAt,
    String? dataExpiryAt,
  }) async {
    try {
      final data = {
        'device_id': deviceId,
        'last_sync_at': lastSyncAt,
        if (dataExpiryAt != null) 'data_expiry_at': dataExpiryAt,
      };

      final response = await _dio.postUri(
        Uri.parse(ApiEndpoints.syncDeltas.path),
        data: data,
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to fetch deltas');
      }

      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw Exception('Network error fetching deltas: ${e.message}');
    } catch (e) {
      throw Exception('Error fetching deltas: $e');
    }
  }
}
