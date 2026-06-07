import 'package:flutter_test/flutter_test.dart';

import '../_base_page.dart';

class DashboardDesktopPage extends BasePage {
  DashboardDesktopPage(super.tester);

  static const String subtitleText = 'Welcome to the admin panel';

  Future<void> waitUntilVisible() async {
    await pumpUntilFound(find.text(subtitleText));
  }

  void expectDashboardVisible() {
    expect(find.text(subtitleText), findsOneWidget);
  }
}
