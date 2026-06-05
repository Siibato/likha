import 'package:flutter_test/flutter_test.dart';
import 'package:likha/presentation/widgets/shared/forms/styled_text_field.dart';
import 'package:likha/presentation/widgets/shared/forms/styled_dropdown.dart';
import 'package:likha/presentation/widgets/shared/forms/styled_button.dart';

import '../_base_page.dart';

class CreateAccountDesktopPage extends BasePage {
  CreateAccountDesktopPage(super.tester);

  static const String titleText = 'Create Account';
  static const String createButtonLabel = 'Create Account';

  Future<void> waitUntilVisible() async {
    await pumpUntilFound(find.text(titleText));
  }

  Future<void> enterUsername(String username) async {
    final fields = find.byType(StyledTextField);
    await tester.enterText(fields.at(0), username);
    await tester.pump();
  }

  Future<void> enterFullName(String fullName) async {
    final fields = find.byType(StyledTextField);
    await tester.enterText(fields.at(1), fullName);
    await tester.pump();
  }

  Future<void> selectRole(String role) async {
    await tester.tap(find.byType(StyledDropdown<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text(role).last);
    await tester.pumpAndSettle();
  }

  Future<void> tapCreateAccount() async {
    await tester.tap(find.widgetWithText(StyledButton, createButtonLabel));
    await tester.pumpAndSettle(const Duration(seconds: 3));
  }
}
