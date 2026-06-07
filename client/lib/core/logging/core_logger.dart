import 'package:likha/core/logging/app_logger.dart';

/// Logger for core infrastructure: event bus, sync queue, startup.
class CoreLogger extends AppLogger {
  static final CoreLogger instance = CoreLogger._();

  CoreLogger._() : super(tag: '[CORE]', envKey: 'CORE_LOGGING_ENABLED');
}
