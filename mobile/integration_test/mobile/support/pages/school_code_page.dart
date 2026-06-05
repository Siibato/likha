import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:likha/presentation/widgets/shared/forms/styled_text_field.dart';

import '_base_page.dart';

class SchoolCodePage extends BasePage {
  SchoolCodePage(super.tester);

  static const String titleText = 'Enter your 6-character school code';
  static const String connectLabel = 'Connect';

  Finder get _codeField => find.byType(StyledTextField);
  Finder get _connectButton => find.widgetWithText(ElevatedButton, connectLabel);

  Future<void> waitUntilVisible() async {
    await pumpUntilFound(find.text(titleText));
  }

  Future<void> enterSchoolCode(String code) async {
    await tester.enterText(_codeField, code);
    await tester.pump();
  }

  Future<void> tapConnect() async {
    await tester.tap(_connectButton);
    await tester.pumpAndSettle(const Duration(seconds: 5));
  }
}
