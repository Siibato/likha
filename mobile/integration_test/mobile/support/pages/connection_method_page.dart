import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '_base_page.dart';

class ConnectionMethodPage extends BasePage {
  ConnectionMethodPage(super.tester);

  static const String titleText = 'Connect to your school';
  static const String iHaveSchoolCodeLabel = 'I have a school code';
  static const String scanQRLabel = 'Scan QR code';

  Finder get _iHaveCodeButton => find.widgetWithText(OutlinedButton, iHaveSchoolCodeLabel);
  Finder get _scanQRButton => find.widgetWithText(OutlinedButton, scanQRLabel);

  Future<void> waitUntilVisible() async {
    await pumpUntilFound(find.text(titleText));
  }

  Future<void> tapIHaveSchoolCode() async {
    await tester.tap(_iHaveCodeButton);
    await tester.pumpAndSettle();
  }

  Future<void> tapScanQR() async {
    await tester.tap(_scanQRButton);
    await tester.pumpAndSettle();
  }
}
