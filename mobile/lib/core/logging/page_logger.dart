import 'package:likha/core/logging/app_logger.dart';

/// Logger for UI pages.
class PageLogger extends AppLogger {
  static final PageLogger instance = PageLogger._();

  PageLogger._() : super(tag: '[PAGE]', envKey: 'PAGE_LOGGING_ENABLED');
}
