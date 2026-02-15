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

    // Compare timestamps
    return server.lastModified.isAfter(local.lastModified);
  }
}
