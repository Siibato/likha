import 'package:likha/core/logging/app_logger.dart';

/// Logger for Riverpod provider state management.
class ProviderLogger extends AppLogger {
  static final ProviderLogger instance = ProviderLogger._();

  ProviderLogger._() : super(tag: '[PROVIDER]', envKey: 'PROVIDER_LOGGING_ENABLED');
}
