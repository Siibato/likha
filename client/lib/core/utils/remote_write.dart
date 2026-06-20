import 'dart:async';

import 'package:likha/core/errors/exceptions.dart';
import 'package:likha/core/utils/guard_remote_call.dart';

Future<T> remoteWrite<T>({
  required Future<T> Function() remote,
}) async {
  return guardRemoteCall(remote);
}

void fireRemoteWrite<T>({
  required Future<T> Function() remote,
  void Function(T data)? onSuccess,
  void Function(Object error)? onError,
}) {
  Future.microtask(() async {
    try {
      final data = await guardRemoteCall(remote);
      onSuccess?.call(data);
    } on NetworkException catch (e) {
      onError?.call(e);
    } on ServerException catch (e) {
      onError?.call(e);
    } catch (e) {
      onError?.call(e);
    }
  });
}
