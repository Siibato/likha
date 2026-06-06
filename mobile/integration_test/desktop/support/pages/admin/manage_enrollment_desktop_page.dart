import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:likha/presentation/widgets/shared/search/app_search_bar.dart';

import '../_base_page.dart';

class ManageEnrollmentDesktopPage extends BasePage {
  ManageEnrollmentDesktopPage(super.tester);

  static const String titleText = 'Manage Enrollment';

  Future<void> waitUntilVisible() async {
    await pumpUntilFound(find.text(titleText));
  }

  Future<void> searchStudent(String query) async {
    final searchField = find.descendant(
      of: find.byType(AppSearchBar),
      matching: find.byType(TextField),
    );
    await tester.enterText(searchField, query);
    await tester.pump(const Duration(milliseconds: 600));
  }

  Future<void> tapEnrollStudent(String fullName) async {
    final nameFinder = find.text(fullName);
    final rowFinder = find.ancestor(
      of: nameFinder,
      matching: find.byType(DataRow),
    );
    final enrollFinder = find.descendant(
      of: rowFinder,
      matching: find.text('Enroll'),
    );
    await tester.tap(enrollFinder);
    await tester.pumpAndSettle(const Duration(seconds: 2));
  }

  void expectStudentEnrolled(String fullName) {
    final nameFinder = find.text(fullName);
    final rowFinder = find.ancestor(
      of: nameFinder,
      matching: find.byType(DataRow),
    );
    final statusFinder = find.descendant(
      of: rowFinder,
      matching: find.text('Enrolled'),
    );
    expect(statusFinder, findsOneWidget);
  }

  Future<void> tapBack() async {
    await tester.tap(find.byIcon(Icons.arrow_back_rounded));
    await tester.pumpAndSettle();
  }
}
