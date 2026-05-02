import 'package:dartz/dartz.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:likha/core/errors/failures.dart';
import 'package:likha/domain/grading/usecases/get_grade_items.dart';
import 'package:likha/domain/grading/usecases/create_grade_item.dart';
import 'package:likha/domain/grading/usecases/delete_grade_item.dart';
import 'package:likha/domain/grading/usecases/generate_scores.dart';
import 'package:likha/domain/grading/usecases/get_grading_config.dart';
import 'package:likha/domain/grading/usecases/setup_grading.dart';
import 'package:likha/domain/grading/usecases/update_grading_config.dart';
import 'package:likha/presentation/providers/grading_provider.dart';

import '../../../helpers/fake_entities.dart';

// ── Mocks ─────────────────────────────────────────────────────────────────────

class MockGetGradeItems extends Mock implements GetGradeItems {}
class MockCreateGradeItem extends Mock implements CreateGradeItem {}
class MockDeleteGradeItem extends Mock implements DeleteGradeItem {}
class MockGenerateScores extends Mock implements GenerateScores {}
class MockGetGradingConfig extends Mock implements GetGradingConfig {}
class MockSetupGrading extends Mock implements SetupGrading {}
class MockUpdateGradingConfig extends Mock implements UpdateGradingConfig {}

// ── Helpers ───────────────────────────────────────────────────────────────────

GradeItemsNotifier _buildItemsNotifier({
  MockGetGradeItems? getGradeItems,
  MockCreateGradeItem? createGradeItem,
  MockDeleteGradeItem? deleteGradeItem,
}) {
  return GradeItemsNotifier(
    getGradeItems ?? MockGetGradeItems(),
    createGradeItem ?? MockCreateGradeItem(),
    deleteGradeItem ?? MockDeleteGradeItem(),
    MockGenerateScores(),
  );
}

GradingConfigNotifier _buildConfigNotifier({
  MockGetGradingConfig? getConfig,
  MockSetupGrading? setupGrading,
}) {
  return GradingConfigNotifier(
    getConfig ?? MockGetGradingConfig(),
    setupGrading ?? MockSetupGrading(),
    MockUpdateGradingConfig(),
  );
}

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  final tItem = FakeEntities.gradeItem();
  final tConfig = FakeEntities.gradeConfig();

  setUpAll(() async {
    dotenv.testLoad(fileInput: '');
    registerFallbackValue(GetGradeItemsParams(classId: 'c-1', gradingPeriodNumber: 1));
    registerFallbackValue(SetupGradingParams(
      classId: 'c-1',
      gradeLevel: '7',
      subjectGroup: 'language',
      schoolYear: '2024-2025',
    ));
  });

  // ─────────────────────────────────────────────────────────────────────────
  group('GradeItemsNotifier', () {
    group('loadItems', () {
      test('populates items on success', () async {
        final mockGet = MockGetGradeItems();
        final notifier = _buildItemsNotifier(getGradeItems: mockGet);

        when(() => mockGet(any())).thenAnswer((_) async => Right([tItem]));

        await notifier.loadItems('c-1');

        expect(notifier.state.isLoading, isFalse);
        expect(notifier.state.items.length, 1);
        expect(notifier.state.error, isNull);
      });

      test('sets error on failure', () async {
        final mockGet = MockGetGradeItems();
        final notifier = _buildItemsNotifier(getGradeItems: mockGet);

        when(() => mockGet(any()))
            .thenAnswer((_) async => const Left(ServerFailure('Error')));

        await notifier.loadItems('c-1');

        expect(notifier.state.isLoading, isFalse);
        expect(notifier.state.error, isNotNull);
        expect(notifier.state.items, isEmpty);
      });
    });

    group('createGradeItem', () {
      test('sets successMessage on success', () async {
        final mockCreate = MockCreateGradeItem();
        final mockGet = MockGetGradeItems();
        final notifier = _buildItemsNotifier(
          getGradeItems: mockGet,
          createGradeItem: mockCreate,
        );

        when(() => mockCreate(classId: any(named: 'classId'), data: any(named: 'data')))
            .thenAnswer((_) async => Right(tItem));
        when(() => mockGet(any())).thenAnswer((_) async => Right([tItem]));

        await notifier.createItem('c-1', {
          'title': 'LQ 1',
          'component': 'written_work',
          'total_points': 50,
          'grading_period_number': 1,
        });

        expect(notifier.state.successMessage, isNotNull);
        expect(notifier.state.error, isNull);
      });

      test('sets error on failure', () async {
        final mockCreate = MockCreateGradeItem();
        final notifier = _buildItemsNotifier(createGradeItem: mockCreate);

        when(() => mockCreate(classId: any(named: 'classId'), data: any(named: 'data')))
            .thenAnswer((_) async => const Left(ServerFailure('Create failed')));

        await notifier.createItem('c-1', {
          'title': 'LQ 1',
          'component': 'written_work',
          'total_points': 50,
          'grading_period_number': 1,
        });

        expect(notifier.state.error, isNotNull);
      });
    });

    group('deleteGradeItem', () {
      test('removes item and sets successMessage on success', () async {
        final mockGet = MockGetGradeItems();
        final mockDelete = MockDeleteGradeItem();
        final notifier = _buildItemsNotifier(
          getGradeItems: mockGet,
          deleteGradeItem: mockDelete,
        );

        when(() => mockGet(any())).thenAnswer((_) async => Right([tItem]));
        await notifier.loadItems('c-1');

        when(() => mockDelete(any())).thenAnswer((_) async => const Right(null));
        when(() => mockGet(any())).thenAnswer((_) async => const Right([]));

        await notifier.deleteItem(tItem.id);

        expect(notifier.state.error, isNull);
        expect(notifier.state.successMessage, isNotNull);
      });
    });

    group('initial state', () {
      test('starts empty and not loading', () {
        final notifier = _buildItemsNotifier();
        expect(notifier.state.items, isEmpty);
        expect(notifier.state.isLoading, isFalse);
        expect(notifier.state.error, isNull);
      });
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  group('GradingConfigNotifier', () {
    group('loadConfig', () {
      test('populates configs and marks isConfigured on success', () async {
        final mockGet = MockGetGradingConfig();
        final notifier = _buildConfigNotifier(getConfig: mockGet);

        when(() => mockGet(any())).thenAnswer((_) async => Right([tConfig]));

        await notifier.loadConfig('c-1');

        expect(notifier.state.isLoading, isFalse);
        expect(notifier.state.isConfigured, isTrue);
        expect(notifier.state.configs.length, 1);
        expect(notifier.state.error, isNull);
      });

      test('sets error on failure', () async {
        final mockGet = MockGetGradingConfig();
        final notifier = _buildConfigNotifier(getConfig: mockGet);

        when(() => mockGet(any()))
            .thenAnswer((_) async => const Left(ServerFailure('Config error')));

        await notifier.loadConfig('c-1');

        expect(notifier.state.isLoading, isFalse);
        expect(notifier.state.error, isNotNull);
        expect(notifier.state.isConfigured, isFalse);
      });
    });

    group('setupGrading', () {
      test('sets isConfigured and successMessage on success', () async {
        final mockSetup = MockSetupGrading();
        final mockGet = MockGetGradingConfig();
        final notifier = _buildConfigNotifier(
          setupGrading: mockSetup,
          getConfig: mockGet,
        );

        when(() => mockSetup(any())).thenAnswer((_) async => const Right(null));
        when(() => mockGet(any())).thenAnswer((_) async => Right([tConfig]));

        await notifier.setupGrading(SetupGradingParams(
          classId: 'c-1',
          gradeLevel: '7',
          subjectGroup: 'language',
          schoolYear: '2024-2025',
        ));

        expect(notifier.state.isConfigured, isTrue);
        expect(notifier.state.successMessage, isNotNull);
        expect(notifier.state.error, isNull);
      });

      test('sets error on failure', () async {
        final mockSetup = MockSetupGrading();
        final notifier = _buildConfigNotifier(setupGrading: mockSetup);

        when(() => mockSetup(any()))
            .thenAnswer((_) async => const Left(ServerFailure('Setup failed')));

        await notifier.setupGrading(SetupGradingParams(
          classId: 'c-1',
          gradeLevel: '7',
          subjectGroup: 'language',
          schoolYear: '2024-2025',
        ));

        expect(notifier.state.error, isNotNull);
        expect(notifier.state.isConfigured, isFalse);
      });
    });
  });
}
