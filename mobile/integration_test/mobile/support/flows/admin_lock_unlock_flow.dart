import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../mobile_pages.dart';

class AdminLockUnlockFlow {
  final MobilePages pages;

  AdminLockUnlockFlow(this.pages);

  Future<void> lockAccount(String fullName) async {
    await pages.adminDashboard.tapAccountManagement();
    await pages.accountManagement.waitUntilVisible();
    await pages.accountManagement.tapAccountByName(fullName);
    await pages.accountDetail.waitUntilVisible(fullName);
    await pages.accountDetail.tapLockAccount();
    await pages.accountDetail.confirmLockDialog();
    await pages.tester.pump(const Duration(seconds: 2));
    await pages.tester.tap(find.byIcon(Icons.arrow_back_rounded));
    await pages.tester.pumpAndSettle();
    await pages.adminDashboard.waitUntilVisible();
  }

  Future<void> unlockAccount(String fullName) async {
    await pages.adminDashboard.tapAccountManagement();
    await pages.accountManagement.waitUntilVisible();
    await pages.accountManagement.tapAccountByName(fullName);
    await pages.accountDetail.waitUntilVisible(fullName);
    await pages.accountDetail.tapUnlockAccount();
    await pages.tester.pump(const Duration(seconds: 2));
    await pages.tester.tap(find.byIcon(Icons.arrow_back_rounded));
    await pages.tester.pumpAndSettle();
    await pages.adminDashboard.waitUntilVisible();
  }
}
