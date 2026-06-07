import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:likha/presentation/widgets/shared/forms/styled_text_field.dart';
import 'package:likha/presentation/widgets/shared/forms/styled_dropdown.dart';
import 'package:likha/presentation/widgets/shared/forms/styled_button.dart';

import '../_base_page.dart';

class ClassCreateDesktopPage extends BasePage {
  ClassCreateDesktopPage(super.tester);

  static const String titleText = 'Create Class';
  static const String createButtonLabel = 'Create Class';

  Future<void> waitUntilVisible() async {
    await pumpUntilFound(find.text(titleText));
  }

  Future<void> enterTitle(String title) async {
    final fields = find.byType(StyledTextField);
    await tester.enterText(fields.at(0), title);
    await tester.pump();
  }

  Future<void> enterDescription(String description) async {
    final fields = find.byType(StyledTextField);
    await tester.enterText(fields.at(1), description);
    await tester.pump();
  }

  Future<void> selectTeacher(String teacherName) async {
    await tester.tap(find.byType(StyledDropdown<String?>));
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining(teacherName).last);
    await tester.pumpAndSettle();
  }

  Future<void> toggleAdvisory() async {
    await tester.tap(find.byType(SwitchListTile));
    await tester.pumpAndSettle();
  }

  Future<void> tapCreateClass() async {
    await tester.tap(find.widgetWithText(StyledButton, createButtonLabel));
    await tester.pumpAndSettle(const Duration(seconds: 3));
  }
}
