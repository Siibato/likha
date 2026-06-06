import 'package:flutter_test/flutter_test.dart';

import '../_base_page.dart';

class SyncLoadingPage extends BasePage {
  SyncLoadingPage(super.tester);

  static const String continueAnywayLabel = 'Continue Anyway';

  Finder get _continueAnywayButton => find.text(continueAnywayLabel);

  Future<void> tapContinueAnyway() async {
    await tester.tap(_continueAnywayButton);
    await tester.pumpAndSettle(const Duration(seconds: 3));
  }

  bool isVisible() {
    return _continueAnywayButton.evaluate().isNotEmpty;
  }
}
