import 'package:flutter/material.dart';
import 'package:likha/presentation/pages/mobile/teacher/assignment/assignment_detail_page.dart' as teacher_assignment;
import 'package:likha/presentation/providers/assignment/assignment_detail_provider.dart';
import 'package:likha/presentation/providers/assignment/assignment_list_provider.dart';

import '../../../helpers/widget_test_helpers.dart';

void main() {
  setUp(setUpMockDi);
  tearDown(tearDownMockDi);

  testWidgets('shows default title when no assignment loaded', (tester) async {
    await tester.pumpWidget(ProviderScope(
      overrides: [
        assignmentDetailProvider.overrideWith(
          (_) => FakeAssignmentDetailNotifier(AssignmentDetailState()),
        ),
        assignmentListProvider.overrideWith(
          (_) => FakeAssignmentListNotifier(AssignmentListState()),
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
        assignmentDetailProvider.overrideWith(
          (_) => FakeAssignmentDetailNotifier(AssignmentDetailState(isLoading: true)),
        ),
        assignmentListProvider.overrideWith(
          (_) => FakeAssignmentListNotifier(AssignmentListState()),
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
        assignmentDetailProvider.overrideWith(
          (_) => FakeAssignmentDetailNotifier(AssignmentDetailState()),
        ),
        assignmentListProvider.overrideWith(
          (_) => FakeAssignmentListNotifier(AssignmentListState()),
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
