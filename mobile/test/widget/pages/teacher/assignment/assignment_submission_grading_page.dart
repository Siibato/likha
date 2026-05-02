import 'package:flutter/material.dart';
import 'package:likha/presentation/pages/teacher/assignment/assignment_submission_grading_page.dart';
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
      home: AssignmentSubmissionGradingPage(submissionId: 's1', totalPoints: 100),
    ),
  );
}

void main() {
  setUp(setUpMockDi);
  tearDown(tearDownMockDi);

  testWidgets('shows not found message when no submission loaded', (tester) async {
    await tester.pumpWidget(_buildPage());
    await tester.pump();

    expect(find.text('Submission not found'), findsOneWidget);
  });

  testWidgets('loading state shows spinner', (tester) async {
    await tester.pumpWidget(_buildPage(state: AssignmentState(isLoading: true)));
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('page renders without crash with empty state', (tester) async {
    await tester.pumpWidget(_buildPage());
    await tester.pump();

    expect(find.byType(AssignmentSubmissionGradingPage), findsOneWidget);
  });
}
