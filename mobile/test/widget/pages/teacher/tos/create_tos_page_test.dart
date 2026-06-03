import 'package:flutter/material.dart';
import 'package:likha/presentation/pages/teacher/tos/create_tos_page.dart';
import 'package:likha/presentation/providers/tos_provider.dart';

import '../../../helpers/widget_test_helpers.dart';

Widget _buildPage({TosState? state}) {
  return ProviderScope(
    overrides: [
      tosProvider.overrideWith((_) => FakeTosNotifier(state)),
    ],
    child: const MaterialApp(
      home: CreateTosPage(classId: 'class-1'),
    ),
  );
}

void main() {
  setUp(setUpMockDi);
  tearDown(tearDownMockDi);

  testWidgets('renders Create TOS header', (tester) async {
    await tester.pumpWidget(_buildPage());
    await tester.pump();

    expect(find.text('Create TOS'), findsAtLeastNWidgets(1));
  });

  testWidgets('renders TOS Title input field', (tester) async {
    await tester.pumpWidget(_buildPage());
    await tester.pump();

    expect(find.text('TOS Title'), findsOneWidget);
  });

  testWidgets('loading state shows progress indicator', (tester) async {
    await tester.pumpWidget(_buildPage(state: TosState(isLoading: true)));
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });
}
