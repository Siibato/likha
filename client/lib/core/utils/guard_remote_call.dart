import 'package:likha/core/errors/exceptions.dart';
import 'package:likha/core/network/server_reachability_service.dart';
import 'package:likha/injection_container.dart';

/// Shared reachability gating used by both reads and writes.
///
/// If [ServerReachabilityService.isServerReachable] is false, performs a
/// single live check with [checkNow] and throws [NetworkException] if the
/// server is still unreachable.
///
/// Callers must handle [NetworkException] and [ServerException] themselves.
Future<T> guardRemoteCall<T>(Future<T> Function() remote) async {
  final reachability = sl<ServerReachabilityService>();

  if (!reachability.isServerReachable) {
    final now = await reachability.checkNow();
    if (!now) throw NetworkException('Server unreachable');
  }

  return await remote();
}
