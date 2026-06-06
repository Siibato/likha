import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:likha/main.dart' as app;

import 'support/flows/admin/admin_create_account_flow.dart';
import 'support/flows/admin/admin_lock_unlock_flow.dart';
import 'support/flows/admin/admin_reset_password_flow.dart';
import 'support/flows/admin/admin_setup_flow.dart';
import 'support/flows/admin/class_create_add_students_flow.dart';
import 'support/flows/admin/class_delete_flow.dart';
import 'support/flows/admin/class_reassign_teacher_flow.dart';
import 'support/flows/admin/school_settings_flow.dart';
import 'support/flows/admin/student_activation_flow.dart';
import 'support/desktop_pages.dart';
import '../mobile/support/test_setup_helper.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    await TestSetupHelper.resetAppState();
  });

  group('Admin Activation E2E Flow', () {
    testWidgets('admin activates own account and lands on dashboard',
        (tester) async {
      app.main();
      await tester.pump(const Duration(seconds: 2));

      final pages = DesktopPages(tester);
      final flow = AdminSetupFlow(pages);

      await flow.setupAndLogin();

      pages.adminDashboard.expectDashboardVisible();
    });
  });

  group('Admin Create Account E2E Flow', () {
    testWidgets('admin creates a new student account', (tester) async {
      app.main();
      await tester.pump(const Duration(seconds: 2));

      final pages = DesktopPages(tester);
      final adminSetup = AdminSetupFlow(pages);
      await adminSetup.setupAndLogin();

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final username = 'student_create_$timestamp';
      final fullName = 'Create Student $timestamp';

      final createFlow = AdminCreateAccountFlow(pages);
      await createFlow.createStudentAccount(
        username: username,
        fullName: fullName,
      );

      await pages.adminShell.tapAccounts();
      await pages.accountManagement.waitUntilVisible();
      pages.accountManagement.expectAccountVisible(fullName);
    });
  });

  group('Student Activation & Login E2E Flow', () {
    testWidgets('newly created student activates account and logs in',
        (tester) async {
      app.main();
      await tester.pump(const Duration(seconds: 2));

      final pages = DesktopPages(tester);

      final adminSetup = AdminSetupFlow(pages);
      await adminSetup.setupAndLogin();

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final username = 'student_act_$timestamp';
      final fullName = 'Activation Student $timestamp';

      final createFlow = AdminCreateAccountFlow(pages);
      await createFlow.createStudentAccount(
        username: username,
        fullName: fullName,
      );

      final studentFlow = StudentActivationFlow(pages);
      await studentFlow.activateAndLogin(
        username: username,
        password: 'Student123!',
      );

      pages.home.expectClassesTabVisible();
    });
  });

  group('Admin Lock/Unlock E2E Flow', () {
    testWidgets(
        'admin locks student → student cant login → admin unlocks → student logs in',
        (tester) async {
      app.main();
      await tester.pump(const Duration(seconds: 2));

      final pages = DesktopPages(tester);

      final adminSetup = AdminSetupFlow(pages);
      await adminSetup.setupAndLogin();

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final username = 'student_lock_$timestamp';
      final fullName = 'Lock Student $timestamp';

      final createFlow = AdminCreateAccountFlow(pages);
      await createFlow.createStudentAccount(
        username: username,
        fullName: fullName,
      );

      final studentFlow = StudentActivationFlow(pages);
      await studentFlow.activateAndLogin(
        username: username,
        password: 'Student123!',
      );

      await pages.home.tapProfileTab();
      await pages.home.tapLogout();

      await adminSetup.loginFromLoginPage();

      final lockFlow = AdminLockUnlockFlow(pages);
      await lockFlow.lockAccount(fullName);

      await pages.adminShell.tapLogout();

      await pages.login.waitUntilVisible();
      await pages.login.enterUsername(username);
      await pages.login.tapContinue();
      pages.login.expectLockedErrorVisible();

      await adminSetup.loginFromLoginPage();
      await lockFlow.unlockAccount(fullName);

      await pages.adminShell.tapLogout();

      await pages.login.waitUntilVisible();
      await pages.login.enterUsername(username);
      await pages.login.tapContinue();
      await pages.password.waitUntilVisible();
      await pages.password.enterPassword('Student123!');
      await pages.password.tapLogin();
      await pages.home.waitForClassesTab();
    });
  });

  group('Admin Reset Password E2E Flow', () {
    testWidgets(
        'admin resets student password → student reactivates and logs in',
        (tester) async {
      app.main();
      await tester.pump(const Duration(seconds: 2));

      final pages = DesktopPages(tester);

      final adminSetup = AdminSetupFlow(pages);
      await adminSetup.setupAndLogin();

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final username = 'student_reset_$timestamp';
      final fullName = 'Reset Student $timestamp';

      final createFlow = AdminCreateAccountFlow(pages);
      await createFlow.createStudentAccount(
        username: username,
        fullName: fullName,
      );

      final studentFlow = StudentActivationFlow(pages);
      await studentFlow.activateAndLogin(
        username: username,
        password: 'Student123!',
      );

      await pages.home.tapProfileTab();
      await pages.home.tapLogout();

      await adminSetup.loginFromLoginPage();

      final resetFlow = AdminResetPasswordFlow(pages);
      await resetFlow.resetPassword(fullName);

      await pages.adminShell.tapLogout();

      await pages.login.waitUntilVisible();
      await pages.login.enterUsername(username);
      await pages.login.tapContinue();
      await pages.activateAccount.waitUntilVisible();
      await pages.activateAccount.enterPassword('NewPass123!');
      await pages.activateAccount.enterConfirmPassword('NewPass123!');
      await pages.activateAccount.tapActivate();
      await pages.home.waitForClassesTab();
    });
  });

  group('Admin Create Class & Add Students E2E Flow', () {
    testWidgets('admin creates a class and adds a student to it',
        (tester) async {
      app.main();
      await tester.pump(const Duration(seconds: 2));

      final pages = DesktopPages(tester);
      final adminSetup = AdminSetupFlow(pages);
      await adminSetup.setupAndLogin();

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final classTitle = 'E2E Class $timestamp';

      final classFlow = ClassCreateAddStudentsFlow(pages);
      await classFlow.createClass(
        title: classTitle,
        description: 'E2E test class description',
        teacherDisplayName: '@teacher_01',
      );
      await classFlow.addStudentToClass(
        classTitle: classTitle,
        studentFullName: 'Student Three',
      );

      // Verify student is enrolled
      await pages.classManagement.tapClassByTitle(classTitle);
      await pages.classDetail.waitUntilVisible(classTitle);
      pages.classDetail.expectStudentEnrolled('Student Three');
    });
  });

  group('Admin Re-assign Teacher E2E Flow', () {
    testWidgets('admin re-assigns a class to a different teacher',
        (tester) async {
      app.main();
      await tester.pump(const Duration(seconds: 2));

      final pages = DesktopPages(tester);
      final adminSetup = AdminSetupFlow(pages);
      await adminSetup.setupAndLogin();

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final classTitle = 'Reassign Class $timestamp';

      // Create class with seeded teacher_01
      final classFlow = ClassCreateAddStudentsFlow(pages);
      await classFlow.createClass(
        title: classTitle,
        description: 'Reassign test class',
        teacherDisplayName: '@teacher_01',
      );

      // Re-assign to seeded teacher_02
      final reassignFlow = ClassReassignTeacherFlow(pages);
      await reassignFlow.reassignTeacher(
        classTitle: classTitle,
        newTeacherDisplayName: '@teacher_02',
      );

      // Verify teacher_02 is shown on class detail
      await pages.classManagement.waitUntilVisible();
      await pages.classManagement.tapClassByTitle(classTitle);
      await pages.classDetail.waitUntilVisible(classTitle);
      expect(find.text('Teacher Two'), findsOneWidget);
    });
  });

  group('Admin Delete Class E2E Flow', () {
    testWidgets('admin deletes a class', (tester) async {
      app.main();
      await tester.pump(const Duration(seconds: 2));

      final pages = DesktopPages(tester);
      final adminSetup = AdminSetupFlow(pages);
      await adminSetup.setupAndLogin();

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final classTitle = 'Delete Class $timestamp';

      // Create class with seeded teacher_01
      final classFlow = ClassCreateAddStudentsFlow(pages);
      await classFlow.createClass(
        title: classTitle,
        description: 'Delete test class',
        teacherDisplayName: '@teacher_01',
      );

      // Delete class
      final deleteFlow = ClassDeleteFlow(pages);
      await deleteFlow.deleteClass(classTitle);
    });
  });

  group('Admin School Settings E2E Flow', () {
    testWidgets('admin changes school details and code', (tester) async {
      app.main();
      await tester.pump(const Duration(seconds: 2));

      final pages = DesktopPages(tester);
      final adminSetup = AdminSetupFlow(pages);
      await adminSetup.setupAndLogin();

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final newCode = 'E2E${timestamp.toString().substring(timestamp.toString().length - 3)}';

      final settingsFlow = SchoolSettingsFlow(pages);
      await settingsFlow.updateSchoolSettings(
        schoolName: 'E2E School $timestamp',
        region: 'E2E Region',
        division: 'E2E Division',
        schoolYear: '2025-2026',
        schoolCode: newCode,
      );

      // Change code back to original so other tests aren't affected
      await settingsFlow.updateSchoolSettings(
        schoolName: 'E2E School $timestamp',
        schoolCode: 'E2ETST',
      );
    });
  });
}
