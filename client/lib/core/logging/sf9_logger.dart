import 'package:likha/core/logging/app_logger.dart';

class Sf9Logger extends AppLogger {
  static final Sf9Logger instance = Sf9Logger._();

  Sf9Logger._() : super(tag: '[SF9]', envKey: 'SF9_LOGGING_ENABLED');
}
