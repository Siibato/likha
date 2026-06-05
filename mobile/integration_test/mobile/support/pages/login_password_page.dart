import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '_base_page.dart';

class LoginPasswordPage extends BasePage {
  LoginPasswordPage(super.tester);

  static const String titleText = 'Welcome back';
  static const String loginLabel = 'Login';
  static const String useDifferentUsernameLabel = 'Use a different username';
  static const String passwordIncorrectText = 'Password is incorrect';

  Finder get _passwordField => find.byType(TextField).first;
  Finder get _loginButton => find.widgetWithText(ElevatedButton, loginLabel);
  Finder get _useDifferentUsernameButton => find.widgetWithText(TextButton, useDifferentUsernameLabel);

  Future<void> waitUntilVisible() async {
    await pumpUntilFound(find.text(titleText));
  }

  Future<void> enterPassword(String password) async {
    await tester.enterText(_passwordField, password);
    await tester.pump();
  }

  Future<void> tapLogin() async {
    await tester.tap(_loginButton);
    await tester.pumpAndSettle(const Duration(seconds: 5));
  }

  Future<void> tapUseDifferentUsername() async {
    await tester.tap(_useDifferentUsernameButton);
    await tester.pumpAndSettle();
  }

  void expectWelcomeBackVisible() {
    expect(find.text(titleText), findsOneWidget);
  }

  void expectPasswordIncorrectVisible() {
    expect(find.text(passwordIncorrectText), findsOneWidget);
  }
}
