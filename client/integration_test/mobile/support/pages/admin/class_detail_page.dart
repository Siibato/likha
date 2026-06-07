import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:likha/presentation/widgets/mobile/admin/account/student_action_card.dart';

import '../_base_page.dart';

class ClassDetailPage extends BasePage {
  ClassDetailPage(super.tester);

  Future<void> waitUntilVisible(String classTitle) async {
    await pumpUntilFound(find.text(classTitle));
  }

  Future<void> tapEdit() async {
    await tester.tap(find.byIcon(Icons.edit_rounded));
    await tester.pumpAndSettle();
  }

  Future<void> tapDelete() async {
    await tester.tap(find.byIcon(Icons.delete_outline_rounded));
    await tester.pumpAndSettle();
  }

  Future<void> confirmDeleteDialog() async {
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle(const Duration(seconds: 3));
  }

  Future<void> enterStudentSearch(String query) async {
    await tester.enterText(find.byType(TextField).last, query);
    await tester.pump(const Duration(milliseconds: 600));
  }

  Future<void> tapAddStudent(String fullName) async {
    final cardFinder = find.widgetWithText(StudentActionCard, fullName);
    expect(cardFinder, findsOneWidget);

    final addButton = find.descendant(
      of: cardFinder,
      matching: find.byIcon(Icons.add_circle_outline_rounded),
    );
    await tester.tap(addButton);
    await tester.pumpAndSettle(const Duration(seconds: 2));
  }

  void expectStudentEnrolled(String fullName) {
    final cardFinder = find.widgetWithText(StudentActionCard, fullName);
    expect(cardFinder, findsOneWidget);

    final enrolledFinder = find.descendant(
      of: cardFinder,
      matching: find.text('Enrolled'),
    );
    expect(enrolledFinder, findsOneWidget);
  }

  Future<void> tapBack() async {
    await tester.tap(find.byIcon(Icons.arrow_back_rounded));
    await tester.pumpAndSettle();
  }
}
