import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../desktop_pages.dart';

class AdminSetupFlow {
  final DesktopPages pages;

  AdminSetupFlow(this.pages);

  Future<void> setupAndLogin() async {
    await pages.welcome.waitUntilVisible();
    await pages.welcome.tapGetStarted();
    await pages.connection.tapIHaveSchoolCode();

    await pages.schoolCode.waitUntilVisible();
    await pages.schoolCode.enterSchoolCode('E2ETST');
    await pages.schoolCode.tapConnect();

    await pages.schoolCode.pumpUntilNotFound(find.byType(CircularProgressIndicator));

    await pages.login.waitUntilVisible();
    await pages.login.enterUsername('admin');
    await pages.login.tapContinue();

    final activationFinder = find.text('Create a password to activate your account');
    if (activationFinder.evaluate().isNotEmpty) {
      await pages.activateAccount.enterPassword('Admin123!');
      await pages.activateAccount.enterConfirmPassword('Admin123!');
      await pages.activateAccount.tapActivate();
    } else {
      await pages.password.waitUntilVisible();
      await pages.password.enterPassword('Admin123!');
      await pages.password.tapLogin();
    }

    await pages.adminShell.waitUntilVisible();
  }

  Future<void> loginFromLoginPage() async {
    await pages.login.waitUntilVisible();
    await pages.login.enterUsername('admin');
    await pages.login.tapContinue();

    final activationFinder = find.text('Create a password to activate your account');
    if (activationFinder.evaluate().isNotEmpty) {
      await pages.activateAccount.enterPassword('Admin123!');
      await pages.activateAccount.enterConfirmPassword('Admin123!');
      await pages.activateAccount.tapActivate();
    } else {
      await pages.password.waitUntilVisible();
      await pages.password.enterPassword('Admin123!');
      await pages.password.tapLogin();
    }

    await pages.adminShell.waitUntilVisible();
  }
}
