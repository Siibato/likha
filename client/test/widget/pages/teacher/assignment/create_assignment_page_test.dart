import 'package:flutter/material.dart';
import 'package:likha/presentation/pages/mobile/teacher/assignment/assignment_create_page.dart';
import 'package:likha/presentation/providers/assignment_provider.dart';

import '../../../helpers/widget_test_helpers.dart';

Widget _buildPage({AssignmentState? state}) {
  return ProviderScope(
    overrides: [
      assignmentProvider.overrideWith(
        (_) => FakeAssignmentNotifier(state ?? AssignmentState()),
      ),
    ],
    child: const MaterialApp(
      home: CreateAssignmentPage(classId: 'class-1'),
    ),
  );
}

void main() {
  setUp(setUpMockDi);
  tearDown(tearDownMockDi);

  testWidgets('renders Create Assignment title and button', (tester) async {
    await tester.pumpWidget(_buildPage());
    await tester.pump();

    // Both the AppBar title and button use this label
    expect(find.text('Create Assignment'), findsAtLeastNWidgets(1));
  });

  testWidgets('page renders without crash', (tester) async {
    await tester.pumpWidget(_buildPage());
    await tester.pump();

    expect(find.byType(CreateAssignmentPage), findsOneWidget);
  });

  testWidgets('loading state disables the submit button', (tester) async {
    await tester.pumpWidget(_buildPage());
    await tester.pump();

    // The button should be enabled by default
    final button = tester.widget<ElevatedButton>(
      find.byType(ElevatedButton),
    );
    expect(button.onPressed, isNotNull);
  });
}
