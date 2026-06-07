import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../_base_page.dart';

class AccountDetailDesktopPage extends BasePage {
  AccountDetailDesktopPage(super.tester);

  Future<void> waitUntilVisible(String fullName) async {
    await pumpUntilFound(find.text(fullName));
  }

  Future<void> tapBack() async {
    await tester.tap(find.byIcon(Icons.arrow_back_rounded));
    await tester.pumpAndSettle();
  }
}
