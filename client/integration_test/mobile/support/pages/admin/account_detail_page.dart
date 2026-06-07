import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:likha/presentation/widgets/shared/forms/styled_button.dart';

import '../_base_page.dart';

class AccountDetailPage extends BasePage {
  AccountDetailPage(super.tester);

  static const String lockButtonLabel = 'Lock Account';
  static const String unlockButtonLabel = 'Unlock Account';
  static const String resetPasswordLabel = 'Reset Password';
  static const String lockDialogTitle = 'Lock Account';
  static const String resetDialogTitle = 'Reset Password';
  static const String confirmLockLabel = 'Lock';
  static const String confirmResetLabel = 'Reset';
  static const String cancelLabel = 'Cancel';

  Future<void> waitUntilVisible(String fullName) async {
    await pumpUntilFound(find.text(fullName));
  }

  Future<void> tapLockAccount() async {
    await tester.tap(find.widgetWithText(StyledButton, lockButtonLabel));
    await tester.pumpAndSettle();
  }

  Future<void> tapUnlockAccount() async {
    await tester.tap(find.widgetWithText(StyledButton, unlockButtonLabel));
    await tester.pumpAndSettle();
  }

  Future<void> tapResetPassword() async {
    await tester.tap(find.widgetWithText(StyledButton, resetPasswordLabel));
    await tester.pumpAndSettle();
  }

  Future<void> confirmDialog() async {
    await tester.tap(find.text(confirmResetLabel).last);
    await tester.pumpAndSettle(const Duration(seconds: 3));
  }

  Future<void> confirmLockDialog() async {
    await tester.tap(find.text(confirmLockLabel).last);
    await tester.pumpAndSettle(const Duration(seconds: 3));
  }

  Future<void> enterLockReason(String reason) async {
    await tester.enterText(find.byType(TextField).last, reason);
    await tester.pump();
  }

  Future<void> cancelDialog() async {
    await tester.tap(find.text(cancelLabel).last);
    await tester.pumpAndSettle();
  }

  void expectStatusBadge(String statusLabel) {
    expect(find.text(statusLabel), findsOneWidget);
  }
}
