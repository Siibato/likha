import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../mobile_pages.dart';

class AuthFlow {
  final MobilePages pages;

  AuthFlow(this.pages);

  Future<void> _login({
    required String schoolCode,
    required String username,
    required String password,
  }) async {
    await pages.welcome.waitUntilVisible();
    await pages.welcome.tapGetStarted();
    await pages.connection.tapIHaveSchoolCode();

    await pages.schoolCode.waitUntilVisible();
    await pages.schoolCode.enterSchoolCode(schoolCode);
    await pages.schoolCode.tapConnect();

    await pages.schoolCode.pumpUntilNotFound(find.byType(CircularProgressIndicator));

    await pages.login.waitUntilVisible();
    await pages.login.enterUsername(username);
    await pages.login.tapContinue();

    await pages.password.waitUntilVisible();
    await pages.password.enterPassword(password);
    await pages.password.tapLogin();

    await pages.home.waitForClassesTab();
  }

  Future<void> loginAsTeacher({
    required String schoolCode,
    required String username,
    required String password,
  }) async {
    await _login(
      schoolCode: schoolCode,
      username: username,
      password: password,
    );
  }

  Future<void> loginAsStudent({
    required String schoolCode,
    required String username,
    required String password,
  }) async {
    await _login(
      schoolCode: schoolCode,
      username: username,
      password: password,
    );
  }

  Future<void> enterWrongPassword({
    required String schoolCode,
    required String username,
    required String password,
  }) async {
    await pages.welcome.waitUntilVisible();
    await pages.welcome.tapGetStarted();
    await pages.connection.tapIHaveSchoolCode();

    await pages.schoolCode.waitUntilVisible();
    await pages.schoolCode.enterSchoolCode(schoolCode);
    await pages.schoolCode.tapConnect();

    await pages.schoolCode.pumpUntilNotFound(find.byType(CircularProgressIndicator));

    await pages.login.waitUntilVisible();
    await pages.login.enterUsername(username);
    await pages.login.tapContinue();

    await pages.password.waitUntilVisible();
    await pages.password.enterPassword(password);
    await pages.password.tapLogin();

    pages.password.expectWelcomeBackVisible();
    pages.password.expectPasswordIncorrectVisible();
  }
}
