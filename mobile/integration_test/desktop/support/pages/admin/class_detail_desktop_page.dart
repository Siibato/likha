import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../_base_page.dart';

class ClassDetailDesktopPage extends BasePage {
  ClassDetailDesktopPage(super.tester);

  Future<void> waitUntilVisible(String classTitle) async {
    await pumpUntilFound(find.text(classTitle));
  }

  Future<void> tapManageEnrollment() async {
    await tester.tap(find.widgetWithText(FilledButton, 'Manage Enrollment'));
    await tester.pumpAndSettle();
  }

  Future<void> tapEdit() async {
    await tester.tap(find.widgetWithText(OutlinedButton, 'Edit Class'));
    await tester.pumpAndSettle();
  }

  Future<void> tapBack() async {
    await tester.tap(find.byIcon(Icons.arrow_back_rounded));
    await tester.pumpAndSettle();
  }

  void expectStudentEnrolled(String fullName) {
    expect(find.text(fullName), findsOneWidget);
  }

  void expectTeacherVisible(String teacherName) {
    expect(find.text(teacherName), findsOneWidget);
  }
}
