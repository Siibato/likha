import 'package:flutter/material.dart';
import 'package:likha/domain/auth/entities/user.dart';
import 'package:likha/presentation/pages/home_page.dart';
import 'package:likha/presentation/providers/auth_notifier.dart';
import 'package:likha/presentation/providers/auth_provider.dart';

import '../helpers/widget_test_helpers.dart';

User _fakeUser(String role) => User(
      id: 'u1',
      username: 'testuser',
      fullName: 'Test User',
      role: role,
      accountStatus: 'active',
      isActive: true,
      createdAt: DateTime(2024),
    );

void main() {
  setUp(setUpMockDi);
  tearDown(tearDownMockDi);

  testWidgets('shows loading spinner when user is null', (tester) async {
    await tester.pumpWidget(ProviderScope(
      overrides: [
        authProvider.overrideWith(
          (_) => FakeAuthNotifier(AuthState(isInitialized: true, isAuthenticated: false)),
        ),
      ],
      child: const MaterialApp(home: HomePage()),
    ));
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('shows error text for unrecognised role', (tester) async {
    await tester.pumpWidget(ProviderScope(
      overrides: [
        authProvider.overrideWith(
          (_) => FakeAuthNotifier(
            AuthState(
              isInitialized: true,
              isAuthenticated: true,
              user: _fakeUser('unknown'),
            ),
          ),
        ),
      ],
      child: const MaterialApp(home: HomePage()),
    ));
    await tester.pump();

    expect(find.text('Unknown role'), findsOneWidget);
  });
}
