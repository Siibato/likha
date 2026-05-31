import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';

import 'package:likha/core/errors/failures.dart';
import 'package:likha/core/events/data_event_bus.dart';
import 'package:likha/domain/classes/usecases/add_student.dart';
import 'package:likha/domain/classes/usecases/create_class.dart';
import 'package:likha/domain/classes/usecases/delete_class.dart';
import 'package:likha/domain/classes/usecases/get_all_classes.dart';
import 'package:likha/domain/classes/usecases/get_class_detail.dart';
import 'package:likha/domain/classes/usecases/get_my_classes.dart';
import 'package:likha/domain/classes/usecases/get_participants.dart';
import 'package:likha/domain/classes/usecases/remove_student.dart';
import 'package:likha/domain/classes/usecases/search_students.dart';
import 'package:likha/domain/classes/usecases/update_class.dart';
import 'package:likha/presentation/providers/class_provider.dart';

import '../../../helpers/fake_entities.dart';

// ── Mocks ─────────────────────────────────────────────────────────────────────

class MockCreateClass extends Mock implements CreateClass {}
class MockGetMyClasses extends Mock implements GetMyClasses {}
class MockGetAllClasses extends Mock implements GetAllClasses {}
class MockGetClassDetail extends Mock implements GetClassDetail {}
class MockUpdateClass extends Mock implements UpdateClass {}
class MockAddStudent extends Mock implements AddStudent {}
class MockRemoveStudent extends Mock implements RemoveStudent {}
class MockSearchStudents extends Mock implements SearchStudents {}
class MockGetParticipants extends Mock implements GetParticipants {}
class MockDeleteClass extends Mock implements DeleteClass {}

// ── Helpers ───────────────────────────────────────────────────────────────────

ClassNotifier _buildNotifier({
  MockGetMyClasses? getMyClasses,
  MockGetAllClasses? getAllClasses,
  MockCreateClass? createClass,
  MockDeleteClass? deleteClass,
}) {
  return ClassNotifier(
    createClass ?? MockCreateClass(),
    getMyClasses ?? MockGetMyClasses(),
    getAllClasses ?? MockGetAllClasses(),
    MockGetClassDetail(),
    MockUpdateClass(),
    MockAddStudent(),
    MockRemoveStudent(),
    MockSearchStudents(),
    MockGetParticipants(),
    deleteClass ?? MockDeleteClass(),
  );
}

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  final tClass = FakeEntities.classEntity();

  setUpAll(() {
    GetIt.instance.registerSingleton<DataEventBus>(DataEventBus());
    registerFallbackValue(CreateClassParams(title: 'Test Class'));
    registerFallbackValue(UpdateClassParams(classId: 'c-1'));
    registerFallbackValue(AddStudentParams(classId: 'c-1', studentId: 's-1'));
  });

  tearDownAll(() async {
    await GetIt.instance.reset();
  });

  group('ClassNotifier', () {
    group('loadClasses', () {
      test('populates classes on success', () async {
        final mockGet = MockGetMyClasses();
        final notifier = _buildNotifier(getMyClasses: mockGet);

        when(() => mockGet(skipBackgroundRefresh: any(named: 'skipBackgroundRefresh')))
            .thenAnswer((_) async => Right([tClass]));

        final states = <ClassState>[];
        notifier.addListener((s) => states.add(s), fireImmediately: false);

        await notifier.loadClasses();

        expect(states.last.isLoading, isFalse);
        expect(states.last.classes.length, 1);
        expect(states.last.error, isNull);
      });

      test('sets error on failure', () async {
        final mockGet = MockGetMyClasses();
        final notifier = _buildNotifier(getMyClasses: mockGet);

        when(() => mockGet(skipBackgroundRefresh: any(named: 'skipBackgroundRefresh')))
            .thenAnswer((_) async => const Left(ServerFailure('server error')));

        final states = <ClassState>[];
        notifier.addListener((s) => states.add(s), fireImmediately: false);

        await notifier.loadClasses();

        expect(states.last.isLoading, isFalse);
        expect(states.last.error, isNotNull);
      });
    });

    group('loadAllClasses', () {
      test('returns all classes in admin mode', () async {
        final mockGetAll = MockGetAllClasses();
        final notifier = _buildNotifier(getAllClasses: mockGetAll);

        when(() => mockGetAll(skipBackgroundRefresh: any(named: 'skipBackgroundRefresh')))
            .thenAnswer((_) async => Right([tClass]));

        final states = <ClassState>[];
        notifier.addListener((s) => states.add(s), fireImmediately: false);

        await notifier.loadAllClasses();

        expect(states.last.classes.length, 1);
        expect(states.last.error, isNull);
      });
    });

    group('createClass', () {
      test('prepends new class to state on success', () async {
        final mockCreate = MockCreateClass();
        final notifier = _buildNotifier(createClass: mockCreate);

        when(() => mockCreate(any())).thenAnswer((_) async => Right(tClass));

        final states = <ClassState>[];
        notifier.addListener((s) => states.add(s), fireImmediately: false);

        await notifier.createClass(title: 'New Class');

        expect(states.last.classes.first.id, tClass.id);
        expect(states.last.successMessage, isNotNull);
        expect(states.last.error, isNull);
      });

      test('sets error when create fails', () async {
        final mockCreate = MockCreateClass();
        final notifier = _buildNotifier(createClass: mockCreate);

        when(() => mockCreate(any()))
            .thenAnswer((_) async => const Left(ServerFailure('create failed')));

        final states = <ClassState>[];
        notifier.addListener((s) => states.add(s), fireImmediately: false);

        await notifier.createClass(title: 'New Class');

        expect(states.last.error, isNotNull);
        expect(states.last.successMessage, isNull);
      });
    });
  });
}
