import 'dart:async';

import 'package:likha/core/errors/exceptions.dart';
import 'package:likha/core/network/server_reachability_service.dart';
import 'package:likha/injection_container.dart';

final _inFlight = <String>{};

Future<T> _executeRemote<T>(Future<T> Function() remote) async {
  final reachability = sl<ServerReachabilityService>();

  if (!reachability.isServerReachable) {
    final now = await reachability.checkNow();
    if (!now) throw NetworkException('Server unreachable');
  }

  return await remote();
}

/// Blocking remote fetch with dedup and reachability gate.
///
/// Throws [NetworkException] if server is unreachable or dedup prevents duplicate.
/// Throws [ServerException] on server error.
Future<T> remoteFetch<T>({
  required String dedupKey,
  required Future<T> Function() remote,
}) async {
  if (_inFlight.contains(dedupKey)) {
    throw NetworkException('Fetch already in progress: $dedupKey');
  }
  _inFlight.add(dedupKey);

  try {
    return await _executeRemote(remote);
  } finally {
    _inFlight.remove(dedupKey);
  }
}

/// Fire-and-forget remote fetch.
///
/// Calls [onSuccess] with fresh data when remote succeeds.
/// [onSuccess] is awaited so dedup key stays locked until local writes complete.
/// All errors are caught silently.
void fireRemoteFetch<T>({
  required String dedupKey,
  required Future<T> Function() remote,
  required Future<void> Function(T data) onSuccess,
}) {
  if (_inFlight.contains(dedupKey)) return;
  _inFlight.add(dedupKey);

  Future.microtask(() async {
    try {
      final data = await _executeRemote(remote);
      await onSuccess(data);
    } on NetworkException {
      // silent
    } on ServerException {
      // silent
    } catch (_) {
      // silent: any unexpected error in onSuccess or remote call
    } finally {
      _inFlight.remove(dedupKey);
    }
  });
}
