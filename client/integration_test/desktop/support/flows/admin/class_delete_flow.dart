import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../desktop_pages.dart';

class ClassDeleteFlow {
  final DesktopPages pages;

  ClassDeleteFlow(this.pages);

  Future<void> deleteClass(String classTitle) async {
    await pages.adminShell.tapClasses();
    await pages.classManagement.waitUntilVisible();
    await pages.classManagement.tapDeleteClass(classTitle);
    // Confirm delete dialog by typing DELETE
    await pages.classManagement.pumpUntilFound(
      find.text('Type DELETE to confirm:'),
    );
    await pages.classManagement.tester.enterText(
      find.byType(TextField).last,
      'DELETE',
    );
    await pages.classManagement.tester.pump();
    await pages.classManagement.tester.tap(find.text('Delete Class'));
    await pages.classManagement.tester.pumpAndSettle(const Duration(seconds: 3));
    await pages.classManagement.waitUntilVisible();
    pages.classManagement.expectClassNotVisible(classTitle);
  }
}
