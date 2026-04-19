import 'dart:async';
import 'package:dio/dio.dart';

/// Checks if the server is reachable by pinging the /health endpoint
/// This is more accurate than device connectivity - "offline" means server unreachable
abstract class ServerReachabilityService {
  bool get isServerReachable;
  Stream<bool> get onServerReachabilityChanged;
  Future<void> initialize();
  void dispose();
  Future<bool> checkNow();
}

class ServerReachabilityServiceImpl implements ServerReachabilityService {
  final Dio _dio;
  final Duration checkInterval;
  final Duration timeout;

  // Adaptive polling constants
  static const Duration _unreachableInterval = Duration(seconds: 10);
  static const Duration _backoffInterval = Duration(seconds: 60);
  static const int _backoffThreshold = 60; // consecutive failures before backoff

  late StreamController<bool> _reachabilityStream;
  Timer? _nextCheck;
  bool _isServerReachable = false;
  int _consecutiveFailures = 0;
  bool _isDisposed = false;
  bool _checkInFlight = false;

  ServerReachabilityServiceImpl(
    this._dio, {
    this.checkInterval = const Duration(seconds: 30),
    this.timeout = const Duration(seconds: 10),
  });

  @override
  bool get isServerReachable => _isServerReachable;

  @override
  Stream<bool> get onServerReachabilityChanged =>
      _reachabilityStream.stream.distinct().asBroadcastStream();

  @override
  Future<void> initialize() async {
    _isDisposed = false;
    _reachabilityStream = StreamController<bool>.broadcast();

    // Initial check
    await checkNow();

    // checkNow() schedules the next one-shot timer internally via _scheduleNext()
  }

  @override
  Future<bool> checkNow() async {
    if (_checkInFlight) return _isServerReachable;
    _checkInFlight = true;

    _nextCheck?.cancel();
    _nextCheck = null;

    try {
      final response = await _dio.get(
        '/api/v1/health',
        options: Options(
          sendTimeout: timeout,
          receiveTimeout: timeout,
          validateStatus: (status) => status != null && status < 500,
        ),
      );

      _isServerReachable = response.statusCode == 200;

      if (_isServerReachable) {
        _consecutiveFailures = 0;
      } else {
        _consecutiveFailures++;
      }

      if (!_isDisposed) {
        _reachabilityStream.add(_isServerReachable);
      }

      return _isServerReachable;
    } catch (e) {
      _isServerReachable = false;
      _consecutiveFailures++;

      if (!_isDisposed) {
        _reachabilityStream.add(false);
      }

      return false;
    } finally {
      _checkInFlight = false;
      _scheduleNext();
    }
  }

  void _scheduleNext() {
    if (_isDisposed) return;

    final Duration interval;
    if (_isServerReachable) {
      interval = checkInterval;
    } else if (_consecutiveFailures < _backoffThreshold) {
      interval = _unreachableInterval;
    } else {
      interval = _backoffInterval;
    }

    _nextCheck = Timer(interval, () {
      unawaited(checkNow());
    });
  }

  @override
  void dispose() {
    _isDisposed = true;
    _nextCheck?.cancel();
    _nextCheck = null;
    _reachabilityStream.close();
  }
}
