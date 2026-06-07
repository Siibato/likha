import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../_base_page.dart';

class AccountManagementDesktopPage extends BasePage {
  AccountManagementDesktopPage(super.tester);

  static const String titleText = 'Account Management';

  Future<void> waitUntilVisible() async {
    await pumpUntilFound(find.text(titleText));
  }

  Future<void> tapCreateAccount() async {
    await tester.tap(find.widgetWithText(FilledButton, 'Create Account'));
    await tester.pumpAndSettle();
  }

  Future<void> tapAccountByName(String fullName) async {
    await tester.tap(find.text(fullName));
    await tester.pumpAndSettle();
  }

  Future<void> openAccountActionsMenu(String fullName) async {
    final nameFinder = find.text(fullName);
    final rowFinder = find.ancestor(
      of: nameFinder,
      matching: find.byType(DataRow),
    );
    final menuFinder = find.descendant(
      of: rowFinder,
      matching: find.byIcon(Icons.more_vert_rounded),
    );
    await tester.tap(menuFinder);
    await tester.pumpAndSettle();
  }

  Future<void> tapLockAccount(String fullName) async {
    await openAccountActionsMenu(fullName);
    await tester.tap(find.text('Lock'));
    await tester.pumpAndSettle();
    // Confirm lock reason dialog
    await tester.tap(find.text('Lock Account'));
    await tester.pumpAndSettle();
  }

  Future<void> tapUnlockAccount(String fullName) async {
    await openAccountActionsMenu(fullName);
    await tester.tap(find.text('Unlock'));
    await tester.pumpAndSettle();
  }

  Future<void> tapResetPassword(String fullName) async {
    await openAccountActionsMenu(fullName);
    await tester.tap(find.text('Reset Password'));
    await tester.pumpAndSettle();
    // Confirm reset dialog
    await tester.tap(find.text('Reset'));
    await tester.pumpAndSettle();
  }

  Future<void> tapDeleteAccount(String fullName) async {
    await openAccountActionsMenu(fullName);
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
    // Confirm delete dialog
    await tester.enterText(find.byType(TextField).last, 'DELETE');
    await tester.pump();
    await tester.tap(find.text('Delete Account'));
    await tester.pumpAndSettle(const Duration(seconds: 3));
  }

  void expectAccountVisible(String fullName) {
    expect(find.text(fullName), findsOneWidget);
  }

  void expectAccountStatus(String fullName, String statusLabel) {
    final nameFinder = find.text(fullName);
    final rowFinder = find.ancestor(
      of: nameFinder,
      matching: find.byType(DataRow),
    );
    final statusFinder = find.descendant(
      of: rowFinder,
      matching: find.text(statusLabel),
    );
    expect(statusFinder, findsOneWidget);
  }
}
