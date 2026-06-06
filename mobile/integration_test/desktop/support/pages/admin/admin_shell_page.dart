import 'package:flutter_test/flutter_test.dart';
import 'package:likha/presentation/pages/desktop/core/desktop_navigation_rail.dart';

import '../_base_page.dart';

class AdminShellPage extends BasePage {
  AdminShellPage(super.tester);

  static const String dashboardLabel = 'Dashboard';
  static const String accountsLabel = 'Accounts';
  static const String classesLabel = 'Classes';
  static const String settingsLabel = 'Settings';
  static const String logoutLabel = 'Log out';

  Future<void> waitUntilVisible() async {
    await pumpUntilFound(find.byType(DesktopNavigationRail));
  }

  Future<void> tapDashboard() async {
    await _tapNavItem(dashboardLabel);
  }

  Future<void> tapAccounts() async {
    await _tapNavItem(accountsLabel);
  }

  Future<void> tapClasses() async {
    await _tapNavItem(classesLabel);
  }

  Future<void> tapSettings() async {
    await _tapNavItem(settingsLabel);
  }

  Future<void> tapLogout() async {
    await _tapNavItem(logoutLabel);
    await tester.pumpAndSettle(const Duration(seconds: 3));
  }

  Future<void> _tapNavItem(String label) async {
    final finder = find.descendant(
      of: find.byType(DesktopNavigationRail),
      matching: find.text(label),
    );
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }
}
