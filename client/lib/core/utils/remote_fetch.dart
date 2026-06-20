import 'dart:async';

import 'package:likha/core/errors/exceptions.dart';
import 'package:likha/core/utils/guard_remote_call.dart';

final _inFlight = <String>{};

Future<T> remoteFetch<T>({
  required String dedupKey,
  required Future<T> Function() remote,
}) async {
  if (_inFlight.contains(dedupKey)) {
    throw NetworkException('Fetch already in progress: $dedupKey');
  }
  _inFlight.add(dedupKey);

  try {
    return await guardRemoteCall(remote);
  } finally {
    _inFlight.remove(dedupKey);
  }
}

void fireRemoteFetch<T>({
  required String dedupKey,
  required Future<T> Function() remote,
  required Future<void> Function(T data) onSuccess,
  void Function(Object error)? onError,
}) {
  if (_inFlight.contains(dedupKey)) return;
  _inFlight.add(dedupKey);

  Future.microtask(() async {
    try {
      final data = await guardRemoteCall(remote);
      await onSuccess(data);
    } on NetworkException catch (e) {
      onError?.call(e);
    } on ServerException catch (e) {
      onError?.call(e);
    } catch (e) {
      onError?.call(e);
    } finally {
      _inFlight.remove(dedupKey);
    }
  });
}
