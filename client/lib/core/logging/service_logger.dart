import 'package:likha/core/logging/app_logger.dart';

class ServiceLogger extends AppLogger {
  static final ServiceLogger instance = ServiceLogger._();

  ServiceLogger._() : super(tag: '[SERVICE]', envKey: 'SERVICE_LOGGING_ENABLED');
}
