import 'package:likha/core/logging/validation_logger.dart';
import 'package:likha/core/validation/services/data_validator.dart';
import 'package:likha/core/validation/models/validation_metadata.dart';
import 'package:likha/core/validation/models/validation_result.dart';
import 'package:likha/core/validation/data_sources/validation_remote_datasource.dart';
import 'package:likha/core/validation/repositories/validation_metadata_repository.dart';
import 'package:likha/core/network/connectivity_service.dart';

class TimestampValidator implements DataValidator {
  final ValidationRemoteDataSource _remoteDataSource;
  final ValidationMetadataRepository _metadataRepository;
  final ConnectivityService _connectivityService;

  TimestampValidator({
    required ValidationRemoteDataSource remoteDataSource,
    required ValidationMetadataRepository metadataRepository,
    required ConnectivityService connectivityService,
  })  : _remoteDataSource = remoteDataSource,
        _metadataRepository = metadataRepository,
        _connectivityService = connectivityService;

  @override
  Future<ValidationResult> validate(String entityType) async {
    // Check if online
    if (!_connectivityService.isOnline) {
      return ValidationResult(
        entityType: entityType,
        isOutdated: false,
        serverTimestamp: DateTime.now(),
        serverRecordCount: 0,
        isOnline: false,
      );
    }

    try {
      // Fetch server metadata (lightweight - just timestamps)
      final serverMetadata = await _remoteDataSource.getMetadata(entityType);

      // Get local metadata
      final localMetadata = await _metadataRepository.getMetadata(entityType);

      // Compare timestamps
      final isOutdated = await isDataOutdated(localMetadata, serverMetadata);

      // Update local validation timestamp
      await _metadataRepository.updateValidationTime(
        entityType,
        serverMetadata,
      );

      return ValidationResult(
        entityType: entityType,
        isOutdated: isOutdated,
        serverTimestamp: serverMetadata.lastModified,
        serverRecordCount: serverMetadata.recordCount,
        isOnline: true,
      );
    } catch (e) {
      // Validation failed - assume offline
      return ValidationResult(
        entityType: entityType,
        isOutdated: false,
        serverTimestamp: DateTime.now(),
        serverRecordCount: 0,
        isOnline: false,
        error: e.toString(),
      );
    }
  }

  @override
  Future<bool> isDataOutdated(
    ValidationMetadata? local,
    ValidationMetadata server,
  ) async {
    return _isOutdated(local, server);
  }

  /// Check if local data is outdated
  bool _isOutdated(ValidationMetadata? local, ValidationMetadata server) {
    // No local metadata = always outdated
    if (local == null) return true;

    // CRITICAL: Check if database was reset (database ID changed)
    // This is the primary cache invalidation mechanism
    if (local.databaseId != null && server.databaseId != null) {
      if (local.databaseId != server.databaseId) {
        ValidationLogger.instance.warn('Database ID changed! Invalidating all caches.');
        return true; // Database was reset/recreated, invalidate everything
      }
    }

    // Compare timestamps
    final timestampOutdated = server.lastModified.isAfter(local.lastModified);

    // Also check if record count changed significantly (catches deletions)
    // If server has 0 records but local has data, or count mismatch > 10%, refresh
    final recordCountMismatch = (local.recordCount - server.recordCount).abs() >
        (local.recordCount * 0.1).toInt() ||
        (server.recordCount == 0 && local.recordCount > 0);

    return timestampOutdated || recordCountMismatch;
  }
}
