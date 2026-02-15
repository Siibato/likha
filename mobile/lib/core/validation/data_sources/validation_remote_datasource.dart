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
      final response = await _dioClient.dio.get('/$entityType/metadata');

      final data = response.data['data'] ?? response.data;

      return ValidationMetadata(
        entityType: entityType,
        lastModified: DateTime.parse(data['last_modified'] as String),
        recordCount: data['record_count'] as int,
        etag: data['etag'] as String?,
        validatedAt: DateTime.now(),
      );
    } catch (e) {
      throw ServerException('Failed to fetch metadata for $entityType: $e');
    }
  }
}
