import 'package:likha/core/logging/app_logger.dart';

/// Logger for local cache operations on learning materials and related datasources.
class CacheLogger extends AppLogger {
  static final CacheLogger instance = CacheLogger._();

  CacheLogger._() : super(tag: '[CACHE]', envKey: 'CACHE_LOGGING_ENABLED');
}
