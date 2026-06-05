import 'package:flutter_test/flutter_test.dart';

abstract class BasePage {
  final WidgetTester tester;
  BasePage(this.tester);

  static const Duration defaultTimeout = Duration(seconds: 10);

  /// Pump until [finder] matches at least one widget.
  Future<void> pumpUntilFound(
    Finder finder, {
    Duration timeout = defaultTimeout,
  }) async {
    final end = DateTime.now().add(timeout);
    while (DateTime.now().isBefore(end)) {
      if (finder.evaluate().isNotEmpty) return;
      await tester.pump(const Duration(milliseconds: 100));
    }
    throw TestFailure('Timed out waiting for $finder');
  }

  /// Pump until [finder] matches no widgets.
  Future<void> pumpUntilNotFound(
    Finder finder, {
    Duration timeout = defaultTimeout,
  }) async {
    final end = DateTime.now().add(timeout);
    while (DateTime.now().isBefore(end)) {
      if (finder.evaluate().isEmpty) return;
      await tester.pump(const Duration(milliseconds: 100));
    }
    throw TestFailure('Timed out waiting for $finder to disappear');
  }
}
