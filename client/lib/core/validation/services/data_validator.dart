import 'package:likha/core/validation/models/validation_metadata.dart';
import 'package:likha/core/validation/models/validation_result.dart';

abstract class DataValidator {
  /// Validate if local data is fresh
  Future<ValidationResult> validate(String entityType);

  /// Compare local metadata with server metadata
  Future<bool> isDataOutdated(
    ValidationMetadata? local,
    ValidationMetadata server,
  );
}
