import 'package:flutter_test/flutter_test.dart';
import 'package:likha/presentation/widgets/shared/forms/styled_text_field.dart';
import 'package:likha/presentation/widgets/shared/forms/styled_dropdown.dart';
import 'package:likha/presentation/widgets/shared/forms/styled_button.dart';

import '_base_page.dart';

class CreateAccountPage extends BasePage {
  CreateAccountPage(super.tester);

  static const String titleText = 'Create Account';
  static const String createButtonLabel = 'Create Account';

  Finder get _usernameField => find.byType(StyledTextField).at(0);
  Finder get _fullNameField => find.byType(StyledTextField).at(1);
  Finder get _createButton => find.widgetWithText(StyledButton, createButtonLabel);

  Future<void> waitUntilVisible() async {
    await pumpUntilFound(find.text(titleText));
  }

  Future<void> enterUsername(String username) async {
    await tester.enterText(_usernameField, username);
    await tester.pump();
  }

  Future<void> enterFullName(String fullName) async {
    await tester.enterText(_fullNameField, fullName);
    await tester.pump();
  }

  Future<void> selectRole(String role) async {
    await tester.tap(find.byType(StyledDropdown<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text(role).last);
    await tester.pumpAndSettle();
  }

  Future<void> tapCreateAccount() async {
    await tester.tap(_createButton);
    await tester.pumpAndSettle(const Duration(seconds: 5));
  }

  void expectCreatePageVisible() {
    expect(find.text(titleText), findsOneWidget);
  }
}
