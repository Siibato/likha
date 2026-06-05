import 'package:flutter_test/flutter_test.dart';
import 'package:likha/presentation/widgets/shared/cards/navigation_card.dart';

import '../_base_page.dart';

class AdminDashboardPage extends BasePage {
  AdminDashboardPage(super.tester);

  static const String titleText = 'Admin Dashboard';
  static const String createAccountLabel = 'Create Account';
  static const String accountManagementLabel = 'Account Management';
  static const String classManagementLabel = 'Class Management';
  static const String logoutLabel = 'Log out';

  Future<void> waitUntilVisible() async {
    await pumpUntilFound(find.text(titleText));
  }

  Future<void> tapCreateAccount() async {
    await tester.tap(find.widgetWithText(NavigationCard, createAccountLabel));
    await tester.pumpAndSettle();
  }

  Future<void> tapAccountManagement() async {
    await tester.tap(find.widgetWithText(NavigationCard, accountManagementLabel));
    await tester.pumpAndSettle();
  }

  Future<void> tapClassManagement() async {
    await tester.tap(find.widgetWithText(NavigationCard, classManagementLabel));
    await tester.pumpAndSettle();
  }

  Future<void> tapLogout() async {
    await tester.tap(find.text(logoutLabel));
    await tester.pumpAndSettle();
  }

  void expectDashboardVisible() {
    expect(find.text(titleText), findsOneWidget);
  }
}
