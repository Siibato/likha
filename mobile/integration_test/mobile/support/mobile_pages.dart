import 'package:flutter_test/flutter_test.dart';

import 'pages/admin/account_detail_page.dart';
import 'pages/admin/account_management_page.dart';
import 'pages/admin/activate_account_page.dart';
import 'pages/admin/admin_dashboard_page.dart';
import 'pages/admin/class_management_page.dart';
import 'pages/admin/class_create_page.dart';
import 'pages/admin/class_detail_page.dart';
import 'pages/admin/class_edit_page.dart';
import 'pages/admin/connection_method_page.dart';
import 'pages/admin/create_account_page.dart';
import 'pages/admin/school_settings_page.dart';
import 'pages/auth/home_page.dart';
import 'pages/auth/login_page.dart';
import 'pages/auth/login_password_page.dart';
import 'pages/auth/school_code_page.dart';
import 'pages/auth/sync_loading_page.dart';
import 'pages/auth/welcome_page.dart';

class MobilePages {
  final WidgetTester tester;

  MobilePages(this.tester);

  late final WelcomePage welcome = WelcomePage(tester);
  late final ConnectionMethodPage connection = ConnectionMethodPage(tester);
  late final SchoolCodePage schoolCode = SchoolCodePage(tester);
  late final LoginPage login = LoginPage(tester);
  late final LoginPasswordPage password = LoginPasswordPage(tester);
  late final ActivateAccountPage activateAccount = ActivateAccountPage(tester);
  late final AdminDashboardPage adminDashboard = AdminDashboardPage(tester);
  late final CreateAccountPage createAccount = CreateAccountPage(tester);
  late final AccountManagementPage accountManagement = AccountManagementPage(tester);
  late final AccountDetailPage accountDetail = AccountDetailPage(tester);
  late final ClassManagementPage classManagement = ClassManagementPage(tester);
  late final ClassCreatePage classCreate = ClassCreatePage(tester);
  late final ClassDetailPage classDetail = ClassDetailPage(tester);
  late final ClassEditPage classEdit = ClassEditPage(tester);
  late final SchoolSettingsPage schoolSettings = SchoolSettingsPage(tester);
  late final SyncLoadingPage syncLoading = SyncLoadingPage(tester);
  late final HomePage home = HomePage(tester);
}
