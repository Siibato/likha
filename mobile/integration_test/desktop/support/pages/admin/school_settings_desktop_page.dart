import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:likha/presentation/widgets/shared/forms/school_settings_form.dart';
import 'package:likha/presentation/widgets/shared/forms/styled_text_field.dart';

import '../_base_page.dart';

class SchoolSettingsDesktopPage extends BasePage {
  SchoolSettingsDesktopPage(super.tester);

  static const String titleText = 'School Settings';
  static const String saveButtonLabel = 'Save Settings';

  Future<void> waitUntilVisible() async {
    await pumpUntilFound(find.text(titleText));
  }

  Future<void> enterSchoolName(String name) async {
    final fields = find.descendant(
      of: find.byType(SchoolSettingsForm),
      matching: find.byType(StyledTextField),
    );
    await tester.enterText(fields.at(0), name);
    await tester.pump();
  }

  Future<void> enterRegion(String region) async {
    final fields = find.descendant(
      of: find.byType(SchoolSettingsForm),
      matching: find.byType(StyledTextField),
    );
    await tester.enterText(fields.at(1), region);
    await tester.pump();
  }

  Future<void> enterDivision(String division) async {
    final fields = find.descendant(
      of: find.byType(SchoolSettingsForm),
      matching: find.byType(StyledTextField),
    );
    await tester.enterText(fields.at(2), division);
    await tester.pump();
  }

  Future<void> enterSchoolYear(String year) async {
    final fields = find.descendant(
      of: find.byType(SchoolSettingsForm),
      matching: find.byType(StyledTextField),
    );
    await tester.enterText(fields.at(3), year);
    await tester.pump();
  }

  Future<void> enterSchoolCode(String code) async {
    final fields = find.descendant(
      of: find.byType(SchoolSettingsForm),
      matching: find.byType(StyledTextField),
    );
    await tester.enterText(fields.at(4), code);
    await tester.pump();
  }

  Future<void> tapSaveSettings() async {
    await tester.tap(find.widgetWithText(ElevatedButton, saveButtonLabel));
    await tester.pumpAndSettle(const Duration(seconds: 3));
  }

  Future<void> confirmCodeChangeDialog() async {
    await tester.tap(find.text('Confirm'));
    await tester.pumpAndSettle(const Duration(seconds: 3));
  }

  void expectPageVisible() {
    expect(find.text(titleText), findsOneWidget);
  }
}
