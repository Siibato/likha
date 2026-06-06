import 'package:flutter_test/flutter_test.dart';

import '../_base_page.dart';

class TeacherClassStudentListPage extends BasePage {
  TeacherClassStudentListPage(super.tester);

  static const String titleText = 'Students';

  Future<void> waitUntilVisible() async {
    await pumpUntilFound(find.text(titleText));
  }

  Future<void> tapStudentByName(String fullName) async {
    await tester.tap(find.text(fullName));
    await tester.pumpAndSettle();
  }

  void expectStudentVisible(String fullName) {
    expect(find.text(fullName), findsOneWidget);
  }
}
