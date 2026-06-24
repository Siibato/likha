import 'package:flutter/material.dart';
import 'package:likha/domain/classes/entities/class_detail.dart';
import 'package:likha/presentation/pages/mobile/teacher/class/class_detail_page.dart';
import 'package:likha/presentation/providers/class_provider.dart';

import '../../../helpers/widget_test_helpers.dart';

// Re-export the new state classes for convenience in tests
export 'package:likha/presentation/providers/class/class_list_provider.dart' show ClassListState;
export 'package:likha/presentation/providers/class/class_detail_provider.dart' show ClassDetailState;

ClassDetail _fakeDetail() => ClassDetail(
      id: 'c1',
      title: 'Grade 10 Science',
      teacherId: 't1',
      isArchived: false,
      students: const [],
      createdAt: DateTime(2024),
      updatedAt: DateTime(2024),
    );

void main() {
  setUp(setUpMockDi);
  tearDown(tearDownMockDi);

  testWidgets('shows spinner while loading', (tester) async {
    await tester.pumpWidget(ProviderScope(
      overrides: [
        classDetailProvider.overrideWith(
          (_) => FakeClassDetailNotifier(ClassDetailState(isLoading: true)),
        ),
        classListProvider.overrideWith(
          (_) => FakeClassListNotifier(ClassListState()),
        ),
      ],
      child: const MaterialApp(home: ClassDetailPage(classId: 'c1')),
    ));
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('shows class title when detail is loaded', (tester) async {
    await tester.pumpWidget(ProviderScope(
      overrides: [
        classDetailProvider.overrideWith(
          (_) => FakeClassDetailNotifier(
            ClassDetailState(isLoading: false, currentClassDetail: _fakeDetail()),
          ),
        ),
        classListProvider.overrideWith(
          (_) => FakeClassListNotifier(ClassListState()),
        ),
      ],
      child: const MaterialApp(home: ClassDetailPage(classId: 'c1')),
    ));
    await tester.pump();

    expect(find.text('Grade 10 Science'), findsOneWidget);
  });

  testWidgets('shows navigation cards when detail is loaded', (tester) async {
    await tester.pumpWidget(ProviderScope(
      overrides: [
        classDetailProvider.overrideWith(
          (_) => FakeClassDetailNotifier(
            ClassDetailState(isLoading: false, currentClassDetail: _fakeDetail()),
          ),
        ),
        classListProvider.overrideWith(
          (_) => FakeClassListNotifier(ClassListState()),
        ),
      ],
      child: const MaterialApp(home: ClassDetailPage(classId: 'c1')),
    ));
    await tester.pump();

    expect(find.text('Assignments'), findsOneWidget);
    expect(find.text('Students'), findsOneWidget);
  });
}
