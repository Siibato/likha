import 'package:flutter_test/flutter_test.dart';
import 'package:likha/presentation/widgets/shared/forms/styled_dropdown.dart';
import 'package:likha/presentation/widgets/shared/forms/styled_button.dart';

import '../_base_page.dart';

class ClassEditPage extends BasePage {
  ClassEditPage(super.tester);

  static const String titleText = 'Edit Class';
  static const String saveButtonLabel = 'Save Changes';

  Future<void> waitUntilVisible() async {
    await pumpUntilFound(find.text(titleText));
  }

  Future<void> selectTeacher(String teacherName) async {
    await tester.tap(find.byType(StyledDropdown<String?>));
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining(teacherName).last);
    await tester.pumpAndSettle();
  }

  Future<void> tapSaveChanges() async {
    await tester.tap(find.widgetWithText(StyledButton, saveButtonLabel));
    await tester.pumpAndSettle(const Duration(seconds: 3));
  }
}
