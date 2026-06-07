import 'package:flutter_test/flutter_test.dart';
import 'package:likha/presentation/widgets/shared/cards/class_card.dart';

import '../_base_page.dart';

class TeacherDashboardPage extends BasePage {
  TeacherDashboardPage(super.tester);

  static const String titleText = 'My Classes';

  Future<void> waitUntilVisible() async {
    await pumpUntilFound(find.text(titleText));
  }

  Future<void> tapClassByTitle(String title) async {
    await tester.tap(find.widgetWithText(ClassCard, title));
    await tester.pumpAndSettle();
  }

  void expectClassVisible(String title) {
    expect(find.widgetWithText(ClassCard, title), findsOneWidget);
  }
}
