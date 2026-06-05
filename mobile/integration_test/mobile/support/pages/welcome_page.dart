import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '_base_page.dart';

class WelcomePage extends BasePage {
  WelcomePage(super.tester);

  static const String subtitleText = 'Your offline classroom, anywhere.';
  static const String getStartedLabel = 'Get Started';

  Finder get _getStartedButton => find.widgetWithText(ElevatedButton, getStartedLabel);

  Future<void> waitUntilVisible() async {
    await pumpUntilFound(find.text(subtitleText));
  }

  Future<void> tapGetStarted() async {
    await tester.tap(_getStartedButton);
    await tester.pumpAndSettle();
  }
}
