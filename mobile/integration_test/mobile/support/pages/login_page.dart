import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:likha/presentation/widgets/shared/forms/styled_text_field.dart';

import '_base_page.dart';

class LoginPage extends BasePage {
  LoginPage(super.tester);

  static const String subtitleText = 'Enter your username to continue';
  static const String continueLabel = 'Continue';

  Finder get _usernameField => find.byType(StyledTextField);
  Finder get _continueButton => find.widgetWithText(ElevatedButton, continueLabel);

  Future<void> waitUntilVisible() async {
    await pumpUntilFound(find.text(subtitleText));
  }

  Future<void> enterUsername(String username) async {
    await tester.enterText(_usernameField, username);
    await tester.pump();
  }

  Future<void> tapContinue() async {
    await tester.tap(_continueButton);
    await tester.pumpAndSettle(const Duration(seconds: 5));
  }
}
