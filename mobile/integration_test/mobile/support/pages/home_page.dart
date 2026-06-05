import 'package:flutter_test/flutter_test.dart';

import '_base_page.dart';

class HomePage extends BasePage {
  HomePage(super.tester);

  static const String classesTabText = 'Classes';

  Future<void> waitForClassesTab({Duration timeout = const Duration(seconds: 30)}) async {
    final end = DateTime.now().add(timeout);
    while (DateTime.now().isBefore(end)) {
      await tester.pump(const Duration(seconds: 1));

      final classesFinder = find.text(classesTabText);
      if (classesFinder.evaluate().isNotEmpty) {
        return;
      }

      // If sync failed, tap "Continue Anyway" to proceed
      final continueAnyway = find.text('Continue Anyway');
      if (continueAnyway.evaluate().isNotEmpty) {
        await tester.tap(continueAnyway);
        await tester.pumpAndSettle(const Duration(seconds: 3));
        return;
      }
    }
    throw TestFailure('Timed out waiting for home page / Classes tab');
  }

  void expectClassesTabVisible() {
    expect(find.text(classesTabText), findsAtLeastNWidgets(1));
  }
}
