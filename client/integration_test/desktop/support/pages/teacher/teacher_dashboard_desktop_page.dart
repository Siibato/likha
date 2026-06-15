import 'package:flutter_test/flutter_test.dart';

import '../_base_page.dart';

class TeacherDashboardDesktopPage extends BasePage {
  TeacherDashboardDesktopPage(super.tester);

  static const String titleText = 'My Classes';

  Future<void> waitUntilVisible() async {
    await pumpUntilFound(find.text(titleText));
  }

  Future<void> tapClassByTitle(String title) async {
    await tester.tap(find.text(title).first);
    await tester.pumpAndSettle();
  }

  void expectClassVisible(String title) {
    expect(find.text(title), findsOneWidget);
  }
}
