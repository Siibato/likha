import 'package:flutter_test/flutter_test.dart';

import '../_base_page.dart';

class TeacherClassStudentListDesktopPage extends BasePage {
  TeacherClassStudentListDesktopPage(super.tester);

  static const String titleText = 'Students';

  Future<void> waitUntilVisible() async {
    await pumpUntilFound(find.text(titleText));
  }

  void expectStudentVisible(String fullName) {
    expect(find.text(fullName), findsOneWidget);
  }
}
