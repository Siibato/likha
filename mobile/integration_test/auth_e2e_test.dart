import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:likha/main.dart' as app;
import 'package:likha/presentation/widgets/shared/forms/styled_text_field.dart';

/// E2E test for the full mobile auth flow.
///
/// Prerequisites:
///   - Server running at the URL configured below (default: 10.0.2.2:18080)
///   - Server seeded with E2E data (school code: E2ETST)
///
/// Run via: flutter test integration_test/auth_e2e_test.dart
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    // Wipe all local persisted state so every test starts from a clean install
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    // Inject test server URL before app.main() reads the environment
    dotenv.testLoad(fileInput: '''
API_BASE_URL=http://10.0.2.2:18080
SYNC_LOGGING_ENABLED=false
CORE_LOGGING_ENABLED=false
VALIDATION_LOGGING_ENABLED=false
CACHE_LOGGING_ENABLED=false
REPO_LOGGING_ENABLED=false
PROVIDER_LOGGING_ENABLED=false
PAGE_LOGGING_ENABLED=false
DEV_MODE=false
''');
  });

  group('Auth E2E Flow', () {
    testWidgets('school setup → username check → login → teacher home', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // ── 1. School Setup Page ──────────────────────────────────────────────
      expect(find.text('Welcome to Likha'), findsOneWidget);
      await tester.tap(find.widgetWithText(ElevatedButton, 'Get Started'));
      await tester.pumpAndSettle();

      // ── 2. Connection Method Page ─────────────────────────────────────────
      expect(find.text('Connect to your school'), findsOneWidget);
      await tester.tap(find.widgetWithText(OutlinedButton, 'I have a school code'));
      await tester.pumpAndSettle();

      // ── 3. School Code Page ───────────────────────────────────────────────
      expect(find.text('Enter your 6-character school code'), findsOneWidget);
      await tester.enterText(find.byType(StyledTextField), 'E2ETST');
      await tester.pump();
      await tester.tap(find.widgetWithText(ElevatedButton, 'Connect'));
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // After successful connection the app restarts to AuthWrapper → LoginPage
      expect(find.text('Welcome to Likha'), findsOneWidget);
      expect(find.widgetWithText(ElevatedButton, 'Continue'), findsOneWidget);

      // ── 4. Login Page (username) ──────────────────────────────────────────
      await tester.enterText(find.byType(StyledTextField), 'teacher_01');
      await tester.pump();
      await tester.tap(find.widgetWithText(ElevatedButton, 'Continue'));
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // ── 5. Login Password Page ────────────────────────────────────────────
      expect(find.text('Welcome back'), findsOneWidget);
      expect(find.text('Signing in as teacher_01'), findsOneWidget);

      // The password field is a raw TextFormField; StyledTextField is a TextFormField too,
      // so on this screen there is exactly one TextField descendant.
      await tester.enterText(find.byType(TextField).first, 'teacher123');
      await tester.pump();
      await tester.tap(find.widgetWithText(ElevatedButton, 'Login'));
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // ── 6. Post-login: wait for Home or handle SyncLoadingPage ─────────────
      // Poll until we see the teacher shell bottom nav (or bail out on sync failure)
      for (int i = 0; i < 30; i++) {
        await tester.pump(const Duration(seconds: 1));

        final classesFinder = find.text('Classes');
        if (classesFinder.evaluate().isNotEmpty) {
          break;
        }

        // If sync failed, tap "Continue Anyway" to proceed
        final continueAnyway = find.text('Continue Anyway');
        if (continueAnyway.evaluate().isNotEmpty) {
          await tester.tap(continueAnyway);
          await tester.pumpAndSettle(const Duration(seconds: 3));
          break;
        }
      }

      expect(find.text('Classes'), findsOneWidget,
          reason: 'Expected to reach teacher home page with "Classes" nav item');
    });

    testWidgets('school setup → student login → student home', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // ── School Setup ──────────────────────────────────────────────────────
      expect(find.text('Welcome to Likha'), findsOneWidget);
      await tester.tap(find.widgetWithText(ElevatedButton, 'Get Started'));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(OutlinedButton, 'I have a school code'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(StyledTextField), 'E2ETST');
      await tester.pump();
      await tester.tap(find.widgetWithText(ElevatedButton, 'Connect'));
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // ── Login as student ────────────────────────────────────────────────
      expect(find.text('Welcome to Likha'), findsOneWidget);
      await tester.enterText(find.byType(StyledTextField), 'student_01');
      await tester.pump();
      await tester.tap(find.widgetWithText(ElevatedButton, 'Continue'));
      await tester.pumpAndSettle(const Duration(seconds: 5));

      expect(find.text('Welcome back'), findsOneWidget);
      await tester.enterText(find.byType(TextField).first, 'student123');
      await tester.pump();
      await tester.tap(find.widgetWithText(ElevatedButton, 'Login'));
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // ── Wait for student home ─────────────────────────────────────────────
      for (int i = 0; i < 30; i++) {
        await tester.pump(const Duration(seconds: 1));

        final classesFinder = find.text('Classes');
        if (classesFinder.evaluate().isNotEmpty) {
          break;
        }

        final continueAnyway = find.text('Continue Anyway');
        if (continueAnyway.evaluate().isNotEmpty) {
          await tester.tap(continueAnyway);
          await tester.pumpAndSettle(const Duration(seconds: 3));
          break;
        }
      }

      expect(find.text('Classes'), findsOneWidget,
          reason: 'Expected to reach student home page with "Classes" nav item');
    });

    testWidgets('wrong password shows error and does not log in', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // ── School Setup ──────────────────────────────────────────────────────
      await tester.tap(find.widgetWithText(ElevatedButton, 'Get Started'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(OutlinedButton, 'I have a school code'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(StyledTextField), 'E2ETST');
      await tester.pump();
      await tester.tap(find.widgetWithText(ElevatedButton, 'Connect'));
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // ── Login with wrong password ─────────────────────────────────────────
      await tester.enterText(find.byType(StyledTextField), 'teacher_01');
      await tester.pump();
      await tester.tap(find.widgetWithText(ElevatedButton, 'Continue'));
      await tester.pumpAndSettle(const Duration(seconds: 5));

      await tester.enterText(find.byType(TextField).first, 'wrongpassword');
      await tester.pump();
      await tester.tap(find.widgetWithText(ElevatedButton, 'Login'));
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Should still be on password page with an error indicator
      expect(find.text('Welcome back'), findsOneWidget);
      // After a failed attempt the red banner appears
      expect(find.text('Password is incorrect'), findsOneWidget);
    });
  });
}
