import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:likha/domain/classes/entities/class_detail.dart';
import 'package:likha/presentation/pages/teacher/class/class_detail_page.dart';
import 'package:likha/presentation/providers/class_provider.dart';

import '../../../helpers/widget_test_helpers.dart';

ClassDetail _fakeDetail() => ClassDetail(
      id: 'c1',
      title: 'Grade 10 Science',
      teacherId: 't1',
      isArchived: false,
      students: [],
      createdAt: DateTime(2024),
      updatedAt: DateTime(2024),
    );

void main() {
  setUp(setUpMockDi);
  tearDown(tearDownMockDi);

  testWidgets('shows spinner while loading', (tester) async {
    await tester.pumpWidget(ProviderScope(
      overrides: [
        classProvider.overrideWith(
          (_) => FakeClassNotifier(ClassState(isLoading: true)),
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
        classProvider.overrideWith(
          (_) => FakeClassNotifier(
            ClassState(isLoading: false, currentClassDetail: _fakeDetail()),
          ),
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
        classProvider.overrideWith(
          (_) => FakeClassNotifier(
            ClassState(isLoading: false, currentClassDetail: _fakeDetail()),
          ),
        ),
      ],
      child: const MaterialApp(home: ClassDetailPage(classId: 'c1')),
    ));
    await tester.pump();

    expect(find.text('Assignments'), findsOneWidget);
    expect(find.text('Students'), findsOneWidget);
  });
}
