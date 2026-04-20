import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:likha/presentation/providers/auth_notifier.dart';
import 'package:likha/presentation/providers/auth_provider.dart';
import 'package:likha/presentation/widgets/auth_wrapper.dart';

import '../helpers/widget_test_helpers.dart';

void main() {
  setUp(setUpMockDi);
  tearDown(tearDownMockDi);

  testWidgets('shows loading spinner on first frame before school config resolves', (tester) async {
    // getSchoolConfig() is async; before it resolves the wrapper shows a spinner
    await tester.pumpWidget(ProviderScope(
      overrides: [
        authProvider.overrideWith((_) => FakeAuthNotifier()),
      ],
      child: const MaterialApp(home: AuthWrapper()),
    ));

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('shows setup page when school config is null', (tester) async {
    // Default mock: getSchoolConfig() returns null (no school configured)
    await tester.pumpWidget(ProviderScope(
      overrides: [
        authProvider.overrideWith((_) => FakeAuthNotifier()),
      ],
      child: const MaterialApp(home: AuthWrapper()),
    ));

    // First pump runs the addPostFrameCallback; second pump flushes the async mock Future
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // _schoolConfigInitialized = true, _hasSchoolConfig = false → SchoolSetupPage shown.
    expect(
      find.byType(CircularProgressIndicator),
      findsNothing,
      reason: 'AuthWrapper should no longer be in its initial loading state',
    );
    expect(find.text('Welcome to Likha'), findsOneWidget);
  });

  testWidgets('does not show auth content until school check completes', (tester) async {
    await tester.pumpWidget(ProviderScope(
      overrides: [
        authProvider.overrideWith(
          (_) => FakeAuthNotifier(
            AuthState(isInitialized: true, isAuthenticated: false),
          ),
        ),
      ],
      child: const MaterialApp(home: AuthWrapper()),
    ));

    // Before school config resolves, shows loading — not the login form
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.byType(TextFormField), findsNothing);
  });
}
