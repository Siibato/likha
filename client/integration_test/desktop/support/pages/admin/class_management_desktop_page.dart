import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../_base_page.dart';

class ClassManagementDesktopPage extends BasePage {
  ClassManagementDesktopPage(super.tester);

  static const String titleText = 'Class Management';

  Future<void> waitUntilVisible() async {
    await pumpUntilFound(find.text(titleText));
  }

  Future<void> tapCreateClass() async {
    await tester.tap(find.widgetWithText(FilledButton, 'Create Class'));
    await tester.pumpAndSettle();
  }

  Future<void> tapClassByTitle(String title) async {
    await tester.tap(find.text(title));
    await tester.pumpAndSettle();
  }

  Future<void> tapDeleteClass(String title) async {
    final titleFinder = find.text(title);
    final rowFinder = find.ancestor(
      of: titleFinder,
      matching: find.byType(DataRow),
    );
    final deleteFinder = find.descendant(
      of: rowFinder,
      matching: find.byIcon(Icons.delete_outline_rounded),
    );
    await tester.tap(deleteFinder);
    await tester.pumpAndSettle();
  }

  void expectClassVisible(String title) {
    expect(find.text(title), findsOneWidget);
  }

  void expectClassNotVisible(String title) {
    expect(find.text(title), findsNothing);
  }
}
