import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Base class for all subsystem loggers in Likha.
///
/// Subclasses pass their [tag] (e.g. '[CACHE]') and [envKey]
/// (e.g. 'CACHE_LOGGING_ENABLED') to the constructor.
/// log() / debug() calls are no-ops when the env flag is false.
/// warn() and error() always emit output regardless of the flag.
abstract class AppLogger {
  static const int _maxLogLength = 500;

  final String tag;
  final bool _enabled;

  AppLogger({required this.tag, required String envKey})
      : _enabled = _resolveFlag(envKey);

  static bool _resolveFlag(String envKey) {
    final raw = dotenv.env[envKey]?.toLowerCase().trim();
    return raw == 'true' || raw == '1';
  }

  static String _truncate(String message) {
    if (message.length <= _maxLogLength) return message;
    return '${message.substring(0, _maxLogLength)}...(truncated, ${message.length} chars total)';
  }

  /// Gated by the env flag. Use for verbose operational traces.
  void log(String message) {
    if (!_enabled) return;
    debugPrint('$tag ${_truncate(message)}');
  }

  /// Alias for log(). Keeps callsites readable.
  void debug(String message) => log(message);

  /// Always logs. Use for recoverable issues.
  void warn(String message, [Object? error]) {
    debugPrint('$tag WARN: ${_truncate(message)}${error != null ? ' | ${_truncate(error.toString())}' : ''}');
  }

  /// Always logs. Use for failures that affect behavior.
  void error(String message, [Object? error]) {
    debugPrint('$tag ERROR: ${_truncate(message)}${error != null ? ' | ${_truncate(error.toString())}' : ''}');
  }
}
