import 'package:likha/core/network/dio_client.dart';
import 'package:likha/data/models/sync/conflict_model.dart';
import 'package:likha/data/models/sync/push_response_model.dart';
import 'package:likha/data/models/sync/full_sync_response_model.dart';
import 'package:likha/data/models/sync/delta_sync_response_model.dart';
import 'package:likha/data/datasources/remote/operations/sync/sync.dart' as ops;

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

  @override
  Future<PushResponseModel> pushOperations({
    required List<Map<String, dynamic>> operations,
  }) =>
      ops.pushOperations(
        dioClient,
        operations: operations,
      );

  @override
  Future<ConflictResolutionResponse> resolveConflict({
    required ConflictResolutionRequest request,
  }) =>
      ops.resolveConflict(
        dioClient,
        request: request,
      );

  @override
  Future<Map<String, dynamic>?> uploadSubmissionFile({
    required String submissionId,
    required String localPath,
    required String fileName,
  }) =>
      ops.uploadSubmissionFile(
        dioClient,
        submissionId: submissionId,
        localPath: localPath,
        fileName: fileName,
      );

  @override
  Future<void> uploadMaterialFile({
    required String materialId,
    required String localPath,
    required String fileName,
  }) =>
      ops.uploadMaterialFile(
        dioClient,
        materialId: materialId,
        localPath: localPath,
        fileName: fileName,
      );

  @override
  Future<FullSyncResponseModel> fullSync({
    required String deviceId,
    List<String> classIds = const [],
    Duration? receiveTimeout,
  }) =>
      ops.fullSync(
        dioClient,
        deviceId: deviceId,
        classIds: classIds,
        receiveTimeout: receiveTimeout,
      );

  @override
  Future<DeltaSyncResponseModel> deltaSync({
    required String deviceId,
    required String lastSyncAt,
    String? dataExpiryAt,
  }) =>
      ops.deltaSync(
        dioClient,
        deviceId: deviceId,
        lastSyncAt: lastSyncAt,
        dataExpiryAt: dataExpiryAt,
      );
}
