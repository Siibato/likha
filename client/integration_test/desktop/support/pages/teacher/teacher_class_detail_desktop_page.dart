import 'package:flutter_test/flutter_test.dart';

import '../_base_page.dart';

class TeacherClassDetailDesktopPage extends BasePage {
  TeacherClassDetailDesktopPage(super.tester);

  Future<void> waitUntilVisible(String classTitle) async {
    await pumpUntilFound(find.text(classTitle));
  }

  Future<void> tapStudentsTab() async {
    await tester.tap(find.text('Students'));
    await tester.pumpAndSettle();
  }
}
