import 'package:likha/core/logging/app_logger.dart';

/// Logger for data validation services.
class ValidationLogger extends AppLogger {
  static final ValidationLogger instance = ValidationLogger._();

  ValidationLogger._()
      : super(tag: '[VALIDATION]', envKey: 'VALIDATION_LOGGING_ENABLED');
}
