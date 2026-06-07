import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../mobile_pages.dart';

class AdminResetPasswordFlow {
  final MobilePages pages;

  AdminResetPasswordFlow(this.pages);

  Future<void> resetPassword(String fullName) async {
    await pages.adminDashboard.tapAccountManagement();
    await pages.accountManagement.waitUntilVisible();
    await pages.accountManagement.tapAccountByName(fullName);
    await pages.accountDetail.waitUntilVisible(fullName);
    await pages.accountDetail.tapResetPassword();
    await pages.accountDetail.confirmDialog();
    await pages.tester.pump(const Duration(seconds: 2));
    await pages.tester.tap(find.byIcon(Icons.arrow_back_rounded));
    await pages.tester.pumpAndSettle();
    await pages.adminDashboard.waitUntilVisible();
  }
}
