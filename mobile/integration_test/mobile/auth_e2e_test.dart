import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:likha/core/sync/sync_manager.dart';
import 'package:likha/injection_container.dart' as di;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:likha/main.dart' as app;
import 'package:likha/presentation/widgets/shared/forms/styled_text_field.dart';
import 'package:likha/services/storage_service.dart';

/// E2E test for the full mobile auth flow.
///
/// Prerequisites:
///   - Server running at the URL passed via --dart-define=TEST_SERVER_URL
///   - Server seeded with E2E data (school code: E2ETST)
///
/// Run via: flutter test integration_test/mobile/auth_e2e_test.dart
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    if (di.sl.isRegistered<SyncManager>()) {
      di.sl<SyncManager>().reset();
    }

    // Wipe all local persisted state so every test starts from a clean install
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    if (di.sl.isRegistered<StorageService>()) {
      await di.sl<StorageService>().clearAuthData();
    }

    // Read test server URL from dart-define (set by run-mobile-e2e.sh)
    const testServerUrl = String.fromEnvironment(
      'TEST_SERVER_URL',
      defaultValue: 'http://10.0.2.2:8080',
    );

    // Inject test server URL before app.main() reads the environment
    dotenv.testLoad(fileInput: '''
API_BASE_URL=$testServerUrl
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

  Future<void> pumpUntilFound(
    WidgetTester tester,
    Finder finder, {
    Duration timeout = const Duration(seconds: 10),
  }) async {
    final end = DateTime.now().add(timeout);
    while (DateTime.now().isBefore(end)) {
      if (finder.evaluate().isNotEmpty) return;
      await tester.pump(const Duration(milliseconds: 100));
    }
    throw TestFailure('Timed out waiting for $finder');
  }

  group('Auth E2E Flow', () {
    testWidgets('school setup → username check → login → teacher home', (tester) async {
      app.main();
      await tester.pumpAndSettle();
      await pumpUntilFound(tester, find.text('Welcome to Likha'));

      expect(find.text('Welcome to Likha'), findsOneWidget);
      await tester.tap(find.widgetWithText(ElevatedButton, 'Get Started'));
      await tester.pumpAndSettle();

      expect(find.text('Connect to your school'), findsOneWidget);
      await tester.tap(find.widgetWithText(OutlinedButton, 'I have a school code'));
      await tester.pumpAndSettle();

      expect(find.text('Enter your 6-character school code'), findsOneWidget);
      await tester.enterText(find.byType(StyledTextField), 'E2ETST');
      await tester.pump();
      await tester.tap(find.widgetWithText(ElevatedButton, 'Connect'));
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // After successful connection the app restarts to AuthWrapper → LoginPage
      expect(find.text('Welcome to Likha'), findsOneWidget);
      expect(find.widgetWithText(ElevatedButton, 'Continue'), findsOneWidget);

      await tester.enterText(find.byType(StyledTextField), 'teacher_01');
      await tester.pump();
      await tester.tap(find.widgetWithText(ElevatedButton, 'Continue'));
      await tester.pumpAndSettle(const Duration(seconds: 5));

      expect(find.text('Welcome back'), findsOneWidget);
      expect(find.text('Signing in as teacher_01'), findsOneWidget);

      // The password field is a raw TextFormField; StyledTextField is a TextFormField too,
      // so on this screen there is exactly one TextField descendant.
      await tester.enterText(find.byType(TextField).first, 'teacher123');
      await tester.pump();
      await tester.tap(find.widgetWithText(ElevatedButton, 'Login'));
      await tester.pumpAndSettle(const Duration(seconds: 5));

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

      expect(find.text('Classes'), findsOneWidget);
    });

    testWidgets('school setup → student login → student home', (tester) async {
      app.main();
      await tester.pumpAndSettle();
      await pumpUntilFound(tester, find.text('Welcome to Likha'));

      expect(find.text('Welcome to Likha'), findsOneWidget);
      await tester.tap(find.widgetWithText(ElevatedButton, 'Get Started'));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(OutlinedButton, 'I have a school code'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(StyledTextField), 'E2ETST');
      await tester.pump();
      await tester.tap(find.widgetWithText(ElevatedButton, 'Connect'));
      await tester.pumpAndSettle(const Duration(seconds: 5));

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

      expect(find.text('Classes'), findsOneWidget);
    });

    testWidgets('wrong password shows error and does not log in', (tester) async {
      app.main();
      await tester.pumpAndSettle();
      await pumpUntilFound(tester, find.text('Welcome to Likha'));

      await tester.tap(find.widgetWithText(ElevatedButton, 'Get Started'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(OutlinedButton, 'I have a school code'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(StyledTextField), 'E2ETST');
      await tester.pump();
      await tester.tap(find.widgetWithText(ElevatedButton, 'Connect'));
      await tester.pumpAndSettle(const Duration(seconds: 5));

      await tester.enterText(find.byType(StyledTextField), 'teacher_01');
      await tester.pump();
      await tester.tap(find.widgetWithText(ElevatedButton, 'Continue'));
      await tester.pumpAndSettle(const Duration(seconds: 5));

      await tester.enterText(find.byType(TextField).first, 'wrongpassword');
      await tester.pump();
      await tester.tap(find.widgetWithText(ElevatedButton, 'Login'));
      await tester.pumpAndSettle(const Duration(seconds: 3));

      expect(find.text('Welcome back'), findsOneWidget);
      expect(find.text('Password is incorrect'), findsOneWidget);
    });
  });
}
