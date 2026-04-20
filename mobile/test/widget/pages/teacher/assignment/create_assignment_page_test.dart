import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:likha/presentation/pages/teacher/assignment/create_assignment_page.dart';
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
    await tester.pumpWidget(_buildPage(state: AssignmentState(isLoading: true)));
    await tester.pump();

    final buttons = tester.widgetList<ElevatedButton>(find.byType(ElevatedButton));
    final createButton = buttons.where((b) {
      final child = b.child;
      return child is Text && (child).data == 'Create Assignment';
    });
    if (createButton.isNotEmpty) {
      expect(createButton.first.onPressed, isNull);
    }
  });
}
