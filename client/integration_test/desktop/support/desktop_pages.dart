import 'package:flutter_test/flutter_test.dart';

import '../../mobile/support/pages/auth/welcome_page.dart';
import '../../mobile/support/pages/admin/connection_method_page.dart';
import '../../mobile/support/pages/auth/school_code_page.dart';
import '../../mobile/support/pages/auth/login_page.dart';
import '../../mobile/support/pages/auth/login_password_page.dart';
import '../../mobile/support/pages/admin/activate_account_page.dart';
import '../../mobile/support/pages/auth/home_page.dart';
import '../../mobile/support/pages/auth/sync_loading_page.dart';

import 'pages/admin/admin_shell_page.dart';
import 'pages/admin/dashboard_desktop_page.dart';
import 'pages/admin/account_management_desktop_page.dart';
import 'pages/admin/account_detail_desktop_page.dart';
import 'pages/admin/create_account_desktop_page.dart';
import 'pages/admin/class_management_desktop_page.dart';
import 'pages/admin/class_create_desktop_page.dart';
import 'pages/admin/class_detail_desktop_page.dart';
import 'pages/admin/class_edit_desktop_page.dart';
import 'pages/admin/school_details_desktop_page.dart';
import 'pages/admin/manage_enrollment_desktop_page.dart';
import 'pages/teacher/teacher_dashboard_desktop_page.dart';
import 'pages/teacher/teacher_class_detail_desktop_page.dart';
import 'pages/teacher/teacher_class_student_list_desktop_page.dart';

class DesktopPages {
  final WidgetTester tester;

  DesktopPages(this.tester);

  // Auth pages (shared with mobile)
  late final WelcomePage welcome = WelcomePage(tester);
  late final ConnectionMethodPage connection = ConnectionMethodPage(tester);
  late final SchoolCodePage schoolCode = SchoolCodePage(tester);
  late final LoginPage login = LoginPage(tester);
  late final LoginPasswordPage password = LoginPasswordPage(tester);
  late final ActivateAccountPage activateAccount = ActivateAccountPage(tester);
  late final HomePage home = HomePage(tester);
  late final SyncLoadingPage syncLoading = SyncLoadingPage(tester);

  // Desktop admin shell & pages
  late final AdminShellPage adminShell = AdminShellPage(tester);
  late final DashboardDesktopPage adminDashboard = DashboardDesktopPage(tester);
  late final CreateAccountDesktopPage createAccount = CreateAccountDesktopPage(tester);
  late final AccountManagementDesktopPage accountManagement = AccountManagementDesktopPage(tester);
  late final AccountDetailDesktopPage accountDetail = AccountDetailDesktopPage(tester);
  late final ClassManagementDesktopPage classManagement = ClassManagementDesktopPage(tester);
  late final ClassCreateDesktopPage classCreate = ClassCreateDesktopPage(tester);
  late final ClassDetailDesktopPage classDetail = ClassDetailDesktopPage(tester);
  late final ClassEditDesktopPage classEdit = ClassEditDesktopPage(tester);
  late final SchoolDetailsDesktopPage schoolDetails = SchoolDetailsDesktopPage(tester);
  late final ManageEnrollmentDesktopPage manageEnrollment = ManageEnrollmentDesktopPage(tester);

  late final TeacherDashboardDesktopPage teacherDashboard = TeacherDashboardDesktopPage(tester);
  late final TeacherClassDetailDesktopPage teacherClassDetail = TeacherClassDetailDesktopPage(tester);
  late final TeacherClassStudentListDesktopPage teacherClassStudentList = TeacherClassStudentListDesktopPage(tester);
}
