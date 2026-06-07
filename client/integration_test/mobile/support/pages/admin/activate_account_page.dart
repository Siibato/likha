import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../_base_page.dart';

class ActivateAccountPage extends BasePage {
  ActivateAccountPage(super.tester);

  static const String subtitleText = 'Create a password to activate your account';
  static const String activateLabel = 'Activate Account';
  static const String backToLoginLabel = 'Back to Login';

  Future<void> waitUntilVisible() async {
    await pumpUntilFound(find.text(subtitleText));
  }

  Future<void> enterPassword(String password) async {
    await tester.enterText(find.byType(TextFormField).at(0), password);
    await tester.pump();
  }

  Future<void> enterConfirmPassword(String password) async {
    await tester.enterText(find.byType(TextFormField).at(1), password);
    await tester.pump();
  }

  Future<void> tapActivate() async {
    await tester.tap(find.widgetWithText(ElevatedButton, activateLabel));
    await tester.pumpAndSettle(const Duration(seconds: 5));
  }

  Future<void> tapBackToLogin() async {
    await tester.tap(find.text(backToLoginLabel));
    await tester.pumpAndSettle();
  }

  void expectActivatePageVisible() {
    expect(find.text(subtitleText), findsOneWidget);
  }
}
