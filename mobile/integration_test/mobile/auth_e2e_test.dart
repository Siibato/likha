import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:likha/main.dart' as app;

import 'support/flows/auth_flow.dart';
import 'support/mobile_pages.dart';
import 'support/test_setup_helper.dart';

/// Server must be running with E2E seed (school code: E2ETST).
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    await TestSetupHelper.resetAppState();
  });

  group('Auth E2E Flow', () {
    testWidgets('school setup → username check → login → teacher home',
        (tester) async {
      app.main();
      await tester.pump(const Duration(seconds: 2));

      final pages = MobilePages(tester);
      final flow = AuthFlow(pages);

      await flow.loginAsTeacher(
        schoolCode: 'E2ETST',
        username: 'teacher_01',
        password: 'teacher123',
      );

      pages.home.expectClassesTabVisible();
    });

    testWidgets('school setup → student login → student home',
        (tester) async {
      app.main();
      await tester.pump(const Duration(seconds: 2));

      final pages = MobilePages(tester);
      final flow = AuthFlow(pages);

      await flow.loginAsStudent(
        schoolCode: 'E2ETST',
        username: 'student_01',
        password: 'student123',
      );

      pages.home.expectClassesTabVisible();
    });

    testWidgets('wrong password shows error and does not log in',
        (tester) async {
      app.main();
      await tester.pump(const Duration(seconds: 2));

      final pages = MobilePages(tester);
      final flow = AuthFlow(pages);

      await flow.enterWrongPassword(
        schoolCode: 'E2ETST',
        username: 'teacher_01',
        password: 'wrongpassword',
      );
    });
  });
}
