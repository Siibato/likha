import 'package:connectivity_plus/connectivity_plus.dart';

abstract class ConnectivityService {
  bool get isOnline;
  Stream<bool> get onConnectivityChanged;
  Future<void> initialize();
  void dispose();
}

class ConnectivityServiceImpl implements ConnectivityService {
  final Connectivity _connectivity;
  late Stream<bool> _connectivityStream;
  bool _isOnline = true;

  ConnectivityServiceImpl(this._connectivity);

  @override
  bool get isOnline => _isOnline;

  @override
  Stream<bool> get onConnectivityChanged => _connectivityStream;

  @override
  Future<void> initialize() async {
    // Check current connectivity status
    final result = await _connectivity.checkConnectivity();
    _isOnline = _parseConnectivityResult(result);

    // Listen to connectivity changes with debouncing
    _connectivityStream = _connectivity.onConnectivityChanged
        .map(_parseConnectivityResult)
        .distinct() // Only emit when value actually changes
        .asBroadcastStream();
  }

  @override
  void dispose() {
    // No cleanup needed for broadcast stream
  }

  bool _parseConnectivityResult(ConnectivityResult result) {
    return result != ConnectivityResult.none;
  }
}
