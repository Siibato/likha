import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../mobile_pages.dart';

class StudentActivationFlow {
  final MobilePages pages;

  StudentActivationFlow(this.pages);

  Future<void> activateAndLogin({
    required String username,
    required String password,
  }) async {
    await pages.adminDashboard.tapLogout();

    await pages.welcome.waitUntilVisible();
    await pages.welcome.tapGetStarted();
    await pages.connection.tapIHaveSchoolCode();

    await pages.schoolCode.waitUntilVisible();
    await pages.schoolCode.enterSchoolCode('E2ETST');
    await pages.schoolCode.tapConnect();

    await pages.schoolCode.pumpUntilNotFound(find.byType(CircularProgressIndicator));

    await pages.login.waitUntilVisible();
    await pages.login.enterUsername(username);
    await pages.login.tapContinue();

    await pages.activateAccount.waitUntilVisible();
    await pages.activateAccount.enterPassword(password);
    await pages.activateAccount.enterConfirmPassword(password);
    await pages.activateAccount.tapActivate();

    await pages.home.waitForClassesTab();
  }
}
