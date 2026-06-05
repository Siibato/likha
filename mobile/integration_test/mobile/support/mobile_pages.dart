import 'package:flutter_test/flutter_test.dart';

import 'pages/connection_method_page.dart';
import 'pages/home_page.dart';
import 'pages/login_page.dart';
import 'pages/login_password_page.dart';
import 'pages/school_code_page.dart';
import 'pages/sync_loading_page.dart';
import 'pages/welcome_page.dart';

/// Registry of all page objects for a single test.
///
/// Usage:
/// ```dart
/// final pages = MobilePages(tester);
/// await pages.welcome.tapGetStarted();
/// ```
class MobilePages {
  final WidgetTester tester;

  MobilePages(this.tester);

  late final WelcomePage welcome = WelcomePage(tester);
  late final ConnectionMethodPage connection = ConnectionMethodPage(tester);
  late final SchoolCodePage schoolCode = SchoolCodePage(tester);
  late final LoginPage login = LoginPage(tester);
  late final LoginPasswordPage password = LoginPasswordPage(tester);
  late final SyncLoadingPage syncLoading = SyncLoadingPage(tester);
  late final HomePage home = HomePage(tester);
}
