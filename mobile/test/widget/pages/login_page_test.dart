import 'package:flutter/material.dart';
import 'package:likha/presentation/pages/login_page.dart';
import 'package:likha/presentation/providers/auth_notifier.dart';
import 'package:likha/presentation/providers/auth_provider.dart';

import '../helpers/widget_test_helpers.dart';

void main() {
  setUp(setUpMockDi);
  tearDown(tearDownMockDi);

  testWidgets('renders username field and continue button', (tester) async {
    await tester.pumpWidget(ProviderScope(
      overrides: [
        authProvider.overrideWith((_) => FakeAuthNotifier(AuthState())),
      ],
      child: const MaterialApp(home: LoginPage()),
    ));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Welcome to Likha'), findsOneWidget);
    expect(find.text('Continue'), findsOneWidget);
    expect(find.byType(TextFormField), findsOneWidget);
  });

  testWidgets('empty username shows validation error on submit', (tester) async {
    await tester.pumpWidget(ProviderScope(
      overrides: [
        authProvider.overrideWith((_) => FakeAuthNotifier(AuthState())),
      ],
      child: const MaterialApp(home: LoginPage()),
    ));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    await tester.tap(find.text('Continue'));
    await tester.pump();

    expect(find.text('Please enter your username'), findsOneWidget);
  });

  testWidgets('loading state shows spinner and disables button', (tester) async {
    await tester.pumpWidget(ProviderScope(
      overrides: [
        authProvider.overrideWith(
          (_) => FakeAuthNotifier(AuthState(isLoading: true)),
        ),
      ],
      child: const MaterialApp(home: LoginPage()),
    ));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.byType(CircularProgressIndicator), findsWidgets);
  });
}
