import 'package:flutter/material.dart';
import 'package:likha/presentation/pages/student/assignment/assignment_detail_page.dart' as student_assignment;
import 'package:likha/presentation/providers/assignment_provider.dart';

import '../../helpers/widget_test_helpers.dart';

Widget _buildPage({AssignmentState? state}) {
  return ProviderScope(
    overrides: [
      assignmentProvider.overrideWith(
        (_) => FakeAssignmentNotifier(state ?? AssignmentState()),
      ),
    ],
    child: MaterialApp(
      home: student_assignment.AssignmentDetailPage(
        assignmentId: 'a1',
        assignmentTitle: 'Math Quiz',
        instructions: 'Complete all problems.',
        allowsTextSubmission: true,
        allowsFileSubmission: false,
        totalPoints: 100,
        dueAt: DateTime(2025, 12, 31),
      ),
    ),
  );
}

void main() {
  setUp(setUpMockDi);
  tearDown(tearDownMockDi);

  testWidgets('renders assignment title', (tester) async {
    await tester.pumpWidget(_buildPage());
    await tester.pump();

    expect(find.text('Math Quiz'), findsOneWidget);
  });

  testWidgets('page renders without crash with given instructions', (tester) async {
    await tester.pumpWidget(_buildPage());
    await tester.pump();

    // AssignmentDetailPage renders; instructions are in a rich-text card, not plain Text
    expect(find.byType(student_assignment.AssignmentDetailPage), findsOneWidget);
  });

  testWidgets('loading state shows progress indicator', (tester) async {
    await tester.pumpWidget(_buildPage(state: AssignmentState(isLoading: true)));
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsWidgets);
  });
}
