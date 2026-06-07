import 'package:flutter_test/flutter_test.dart';

import '../_base_page.dart';

class TeacherStudentDetailPage extends BasePage {
  TeacherStudentDetailPage(super.tester);

  Future<void> waitUntilVisible(String fullName) async {
    await pumpUntilFound(find.text(fullName));
  }

  void expectUsernameVisible(String username) {
    expect(find.text(username), findsOneWidget);
  }

  void expectFullNameVisible(String fullName) {
    expect(find.text(fullName), findsOneWidget);
  }
}
