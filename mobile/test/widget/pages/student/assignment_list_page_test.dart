import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:likha/presentation/widgets/shared/skeletons/assignment_card_skeleton.dart';
import 'package:likha/presentation/pages/student/assignment/assignment_list_page.dart';
import 'package:likha/presentation/widgets/mobile/student/assignment/empty_assignment_state.dart';
import 'package:likha/presentation/providers/assignment_provider.dart';

import '../../helpers/widget_test_helpers.dart';

void main() {
  setUp(setUpMockDi);
  tearDown(tearDownMockDi);

  testWidgets('shows Assignments header', (tester) async {
    await tester.pumpWidget(ProviderScope(
      overrides: [
        assignmentProvider.overrideWith(
          (_) => FakeAssignmentNotifier(AssignmentState()),
        ),
      ],
      child: const MaterialApp(home: StudentAssignmentListPage(classId: 'class-1')),
    ));
    await tester.pump();

    expect(find.text('Assignments'), findsOneWidget);
  });

  testWidgets('loading state shows skeleton cards', (tester) async {
    await tester.pumpWidget(ProviderScope(
      overrides: [
        assignmentProvider.overrideWith(
          (_) => FakeAssignmentNotifier(AssignmentState(isLoading: true)),
        ),
      ],
      child: const MaterialApp(home: StudentAssignmentListPage(classId: 'class-1')),
    ));
    await tester.pump();

    expect(find.byType(AssignmentCardSkeleton), findsWidgets);
  });

  testWidgets('empty state shows EmptyAssignmentState when list is empty', (tester) async {
    await tester.pumpWidget(ProviderScope(
      overrides: [
        assignmentProvider.overrideWith(
          (_) => FakeAssignmentNotifier(
            AssignmentState(isLoading: false, assignments: []),
          ),
        ),
      ],
      child: const MaterialApp(home: StudentAssignmentListPage(classId: 'class-1')),
    ));
    await tester.pump();

    expect(find.byType(EmptyAssignmentState), findsOneWidget);
  });
}
