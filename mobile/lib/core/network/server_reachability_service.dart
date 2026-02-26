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

  late StreamController<bool> _reachabilityStream;
  late Timer? _periodicCheck;
  bool _isServerReachable = true;

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
    _reachabilityStream = StreamController<bool>.broadcast();

    // Initial check
    await checkNow();

    // Periodic checks
    _periodicCheck = Timer.periodic(checkInterval, (_) async {
      await checkNow();
    });
  }

  @override
  Future<bool> checkNow() async {
    try {
      final response = await _dio.get(
        '/health',
        options: Options(
          sendTimeout: timeout,
          receiveTimeout: timeout,
          validateStatus: (status) => status != null && status < 500,
        ),
      );

      final wasReachable = _isServerReachable;
      _isServerReachable = response.statusCode == 200;

      if (wasReachable != _isServerReachable) {
        _reachabilityStream.add(_isServerReachable);
      }

      return _isServerReachable;
    } catch (e) {
      final wasReachable = _isServerReachable;
      _isServerReachable = false;

      if (wasReachable) {
        _reachabilityStream.add(false);
      }

      return false;
    }
  }

  @override
  void dispose() {
    _periodicCheck?.cancel();
    _reachabilityStream.close();
  }
}
