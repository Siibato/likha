import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '_base_page.dart';

class AccountManagementPage extends BasePage {
  AccountManagementPage(super.tester);

  static const String titleText = 'Account Management';

  Future<void> waitUntilVisible() async {
    await pumpUntilFound(find.text(titleText));
  }

  Future<void> tapAccountByName(String fullName) async {
    await tester.tap(find.text(fullName));
    await tester.pumpAndSettle();
  }

  void expectAccountVisible(String fullName) {
    expect(find.text(fullName), findsOneWidget);
  }

  void expectAccountStatus(String fullName, String statusLabel) {
    final tileFinder = find.ancestor(
      of: find.text(fullName),
      matching: find.byType(GestureDetector),
    );
    expect(tileFinder, findsOneWidget);
    final statusFinder = find.descendant(
      of: tileFinder,
      matching: find.text(statusLabel),
    );
    expect(statusFinder, findsOneWidget);
  }
}
