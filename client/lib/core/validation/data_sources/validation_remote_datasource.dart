import 'package:likha/core/constants/api_endpoint.dart';
import 'package:likha/core/validation/models/validation_metadata.dart';
import 'package:likha/core/network/dio_client.dart';
import 'package:likha/core/errors/exceptions.dart';

abstract class ValidationRemoteDataSource {
  Future<ValidationMetadata> getMetadata(String entityType);
}

class ValidationRemoteDataSourceImpl implements ValidationRemoteDataSource {
  final DioClient _dioClient;

  ValidationRemoteDataSourceImpl(this._dioClient);

  @override
  Future<ValidationMetadata> getMetadata(String entityType) async {
    try {
      // Map entity types to their metadata endpoints
      final endpoint = _getMetadataEndpoint(entityType);
      if (endpoint == null) {
        throw ServerException('Unknown entity type: $entityType');
      }

      // Import ApiEndpoints at the top of the file
      final data = await _dioClient.getTyped(endpoint);

      // Also fetch the database ID for cache invalidation
      String? databaseId;
      try {
        final dbIdData = await _dioClient.getTyped<Map<String, dynamic>>(
          ApiEndpoint<Map<String, dynamic>>(
            '/api/v1/database-id',
            (json) => json as Map<String, dynamic>,
          ),
        );
        databaseId = dbIdData['database_id'] as String?;
      } catch (e) {
        // Database ID fetch is not critical, continue without it
      }

      return ValidationMetadata(
        entityType: entityType,
        lastModified: DateTime.parse(data['last_modified'] as String),
        recordCount: data['record_count'] as int,
        etag: data['etag'] as String?,
        validatedAt: DateTime.now(),
        databaseId: databaseId,
      );
    } catch (e) {
      throw ServerException('Failed to fetch metadata for $entityType: $e');
    }
  }

  /// Get the appropriate ApiEndpoint for a given entity type's metadata
  ApiEndpoint<Map<String, dynamic>>? _getMetadataEndpoint(String entityType) {
    // Import ApiEndpoints at the top of the file if not already imported
    // These endpoints return { last_modified, record_count, etag }
    switch (entityType) {
      case 'classes':
        return ApiEndpoint<Map<String, dynamic>>(
          '/api/v1/classes/metadata',
          (json) => json as Map<String, dynamic>,
        );
      case 'assessments':
        return ApiEndpoint<Map<String, dynamic>>(
          '/api/v1/assessments/metadata',
          (json) => json as Map<String, dynamic>,
        );
      case 'assignments':
        return ApiEndpoint<Map<String, dynamic>>(
          '/api/v1/assignments/metadata',
          (json) => json as Map<String, dynamic>,
        );
      case 'materials':
        return ApiEndpoint<Map<String, dynamic>>(
          '/api/v1/materials/metadata',
          (json) => json as Map<String, dynamic>,
        );
      default:
        return null;
    }
  }
}
