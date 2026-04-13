import 'package:dio/dio.dart';
import 'package:likha/core/constants/api_endpoints.dart';
import 'package:likha/core/network/api_response.dart';
import 'package:likha/core/network/dio_client.dart';
import 'package:likha/data/models/sync/conflict_model.dart';
import 'package:likha/data/models/sync/push_response_model.dart';
import 'package:likha/data/models/sync/full_sync_response_model.dart';
import 'package:likha/data/models/sync/delta_sync_response_model.dart';

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
  ///
  /// [classIds] - List of class IDs to sync (empty = base request only)
  /// [receiveTimeout] - Custom timeout for receiving the response
  Future<FullSyncResponseModel> fullSync({
    required String deviceId,
    List<String> classIds = const [],
    Duration? receiveTimeout,
  });

  /// Fetch delta sync data on app restart
  Future<DeltaSyncResponseModel> deltaSync({
    required String deviceId,
    required String lastSyncAt,
    String? dataExpiryAt,
  });

  /// Upload a file for a submission (assignment or assessment)
  /// Returns server response with file metadata and ID for reconciliation
  Future<Map<String, dynamic>?> uploadSubmissionFile({
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
      return await dioClient.postTyped(
        ApiEndpoints.syncPush,
        data: {'operations': operations},
      );
    } on DioException catch (e) {
      throw dioClient.handleError(e);
    }
  }

  @override
  Future<ConflictResolutionResponse> resolveConflict({
    required ConflictResolutionRequest request,
  }) async {
    try {
      return await dioClient.postTyped(
        ApiEndpoints.syncResolveConflict,
        data: request.toJson(),
      );
    } on DioException catch (e) {
      throw dioClient.handleError(e);
    }
  }

  @override
  Future<Map<String, dynamic>?> uploadSubmissionFile({
    required String submissionId,
    required String localPath,
    required String fileName,
  }) async {
    try {
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(localPath, filename: fileName),
      });
      final response = await _dio.post(
        ApiEndpoints.assignmentSubmissionUpload(submissionId).path,
        data: formData,
      );
      // Parse and return server response for file ID reconciliation
      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>?;
        return data?['data'] as Map<String, dynamic>?;
      }
      return null;
    } on DioException catch (e) {
      throw dioClient.handleError(e);
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
      throw dioClient.handleError(e);
    }
  }

  @override
  Future<FullSyncResponseModel> fullSync({
    required String deviceId,
    List<String> classIds = const [],
    Duration? receiveTimeout,
  }) async {
    try {
      final data = {
        'device_id': deviceId,
        if (classIds.isNotEmpty) 'class_ids': classIds,
      };

      if (receiveTimeout != null) {
        final response = await _dio.post(
          ApiEndpoints.syncFull.path,
          data: data,
          options: Options(receiveTimeout: receiveTimeout),
        );
        final apiResponse = ApiResponse.fromJson(response.data, (json) => FullSyncResponseModel.fromJson(json as Map<String, dynamic>));
        return apiResponse.unwrap();
      } else {
        return await dioClient.postTyped(
          ApiEndpoints.syncFull,
          data: data,
        );
      }
    } on DioException catch (e) {
      throw dioClient.handleError(e);
    }
  }

  @override
  Future<DeltaSyncResponseModel> deltaSync({
    required String deviceId,
    required String lastSyncAt,
    String? dataExpiryAt,
  }) async {
    try {
      return await dioClient.postTyped(
        ApiEndpoints.syncDeltas,
        data: {
          'device_id': deviceId,
          'last_sync_at': lastSyncAt,
          if (dataExpiryAt != null) 'data_expiry_at': dataExpiryAt,
        },
      );
    } on DioException catch (e) {
      throw dioClient.handleError(e);
    }
  }
}
