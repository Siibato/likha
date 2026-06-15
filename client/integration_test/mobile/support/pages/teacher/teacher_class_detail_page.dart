import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:likha/presentation/widgets/shared/cards/navigation_card.dart';

import '../_base_page.dart';

class TeacherClassDetailPage extends BasePage {
  TeacherClassDetailPage(super.tester);

  Future<void> waitUntilVisible(String classTitle) async {
    await pumpUntilFound(find.text(classTitle));
  }

  Future<void> tapStudentsCard() async {
    await tester.tap(find.widgetWithText(NavigationCard, 'Students'));
    await tester.pumpAndSettle();
  }

  Future<void> tapBack() async {
    await tester.tap(find.byIcon(Icons.arrow_back_rounded));
    await tester.pumpAndSettle();
  }
}
