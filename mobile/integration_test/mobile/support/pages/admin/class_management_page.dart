import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:likha/presentation/widgets/shared/cards/class_card.dart';

import '../_base_page.dart';

class ClassManagementPage extends BasePage {
  ClassManagementPage(super.tester);

  static const String titleText = 'Class Management';

  Future<void> waitUntilVisible() async {
    await pumpUntilFound(find.text(titleText));
  }

  Future<void> tapCreateClass() async {
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
  }

  Future<void> tapClassByTitle(String title) async {
    await tester.tap(find.widgetWithText(ClassCard, title));
    await tester.pumpAndSettle();
  }

  void expectClassVisible(String title) {
    expect(find.widgetWithText(ClassCard, title), findsOneWidget);
  }

  void expectClassNotVisible(String title) {
    expect(find.widgetWithText(ClassCard, title), findsNothing);
  }
}
