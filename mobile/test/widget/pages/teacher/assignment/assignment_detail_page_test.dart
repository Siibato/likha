import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:likha/presentation/pages/teacher/assignment/assignment_detail_page.dart' as teacher_assignment;
import 'package:likha/presentation/providers/assignment_provider.dart';

import '../../../helpers/widget_test_helpers.dart';

void main() {
  setUp(setUpMockDi);
  tearDown(tearDownMockDi);

  testWidgets('shows default title when no assignment loaded', (tester) async {
    await tester.pumpWidget(ProviderScope(
      overrides: [
        assignmentProvider.overrideWith(
          (_) => FakeAssignmentNotifier(AssignmentState()),
        ),
      ],
      child: const MaterialApp(
        home: teacher_assignment.AssignmentDetailPage(assignmentId: 'a1'),
      ),
    ));
    await tester.pump();

    expect(find.text('Assignment Detail'), findsOneWidget);
  });

  testWidgets('loading state shows spinner', (tester) async {
    await tester.pumpWidget(ProviderScope(
      overrides: [
        assignmentProvider.overrideWith(
          (_) => FakeAssignmentNotifier(AssignmentState(isLoading: true)),
        ),
      ],
      child: const MaterialApp(
        home: teacher_assignment.AssignmentDetailPage(assignmentId: 'a1'),
      ),
    ));
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('page renders without crash when state is empty', (tester) async {
    await tester.pumpWidget(ProviderScope(
      overrides: [
        assignmentProvider.overrideWith(
          (_) => FakeAssignmentNotifier(AssignmentState()),
        ),
      ],
      child: const MaterialApp(
        home: teacher_assignment.AssignmentDetailPage(assignmentId: 'a1'),
      ),
    ));
    await tester.pump();

    expect(find.byType(teacher_assignment.AssignmentDetailPage), findsOneWidget);
  });
}
