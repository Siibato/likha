import 'dart:async';
import 'dart:collection';

/// Lightweight semaphore for bounded concurrent async work.
class SyncSemaphore {
  final int maxConcurrency;
  int _running = 0;
  final Queue<Completer<void>> _queue = Queue<Completer<void>>();

  SyncSemaphore({required this.maxConcurrency});

  Future<T> run<T>(Future<T> Function() task) async {
    if (_running >= maxConcurrency) {
      final completer = Completer<void>();
      _queue.add(completer);
      await completer.future;
    }

    _running++;
    try {
      return await task();
    } finally {
      _running--;
      if (_queue.isNotEmpty) {
        _queue.removeFirst().complete();
      }
    }
  }
}
