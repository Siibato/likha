import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:likha/main.dart' as app;

import 'support/flows/auth/auth_flow.dart';
import 'support/flows/teacher/teacher_views_students_flow.dart';
import 'support/mobile_pages.dart';
import 'support/test_setup_helper.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    await TestSetupHelper.resetAppState();
  });

  group('Teacher Views Class Students E2E Flow', () {
    testWidgets(
        'teacher logs in, opens class, views enrolled students and student detail',
        (tester) async {
      app.main();
      await tester.pump(const Duration(seconds: 2));

      final pages = MobilePages(tester);

      final authFlow = AuthFlow(pages);
      await authFlow.loginAsTeacher(
        schoolCode: 'E2ETST',
        username: 'teacher_01',
        password: 'teacher123',
      );

      final flow = TeacherViewsStudentsFlow(pages);
      await flow.viewClassStudentList(classTitle: 'Mathematics 8A');

      pages.teacherClassStudentList.expectStudentVisible('Student One');
      pages.teacherClassStudentList.expectStudentVisible('Student Two');
      pages.teacherClassStudentList.expectStudentVisible('Student Three');

      await flow.viewStudentDetail(studentFullName: 'Student One');
      pages.teacherStudentDetail.expectUsernameVisible('@student_01');
      pages.teacherStudentDetail.expectFullNameVisible('Student One');
    });
  });
}
