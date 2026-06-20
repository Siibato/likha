import 'package:likha/core/logging/app_logger.dart';

/// Logger for assessment statistics computation.
class StatsLogger extends AppLogger {
  static final StatsLogger instance = StatsLogger._();

  StatsLogger._() : super(tag: '[STATS]', envKey: 'STATS_LOGGING_ENABLED');
}
