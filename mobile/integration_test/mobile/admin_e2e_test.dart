import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:likha/main.dart' as app;

import 'support/flows/admin_create_account_flow.dart';
import 'support/flows/admin_lock_unlock_flow.dart';
import 'support/flows/admin_reset_password_flow.dart';
import 'support/flows/admin_setup_flow.dart';
import 'support/flows/student_activation_flow.dart';
import 'support/mobile_pages.dart';
import 'support/test_setup_helper.dart';

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

      final pages = MobilePages(tester);
      final flow = AdminSetupFlow(pages);

      await flow.setupAndLogin();

      pages.adminDashboard.expectDashboardVisible();
    });
  });

  group('Admin Create Account E2E Flow', () {
    testWidgets('admin creates a new student account', (tester) async {
      app.main();
      await tester.pump(const Duration(seconds: 2));

      final pages = MobilePages(tester);
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

      await pages.adminDashboard.tapAccountManagement();
      await pages.accountManagement.waitUntilVisible();
      pages.accountManagement.expectAccountVisible(fullName);
    });
  });

  group('Student Activation & Login E2E Flow', () {
    testWidgets('newly created student activates account and logs in',
        (tester) async {
      app.main();
      await tester.pump(const Duration(seconds: 2));

      final pages = MobilePages(tester);

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

      final pages = MobilePages(tester);

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

      await pages.adminDashboard.tapLogout();

      await pages.login.waitUntilVisible();
      await pages.login.enterUsername(username);
      await pages.login.tapContinue();
      pages.login.expectLockedErrorVisible();

      await adminSetup.loginFromLoginPage();
      await lockFlow.unlockAccount(fullName);

      await pages.adminDashboard.tapLogout();

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

      final pages = MobilePages(tester);

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

      await pages.adminDashboard.tapLogout();

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
}
