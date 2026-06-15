import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';

import 'package:likha/core/errors/failures.dart';
import 'package:likha/domain/tos/usecases/add_competency.dart';
import 'package:likha/domain/tos/usecases/bulk_add_competencies.dart';
import 'package:likha/domain/tos/usecases/create_tos.dart';
import 'package:likha/domain/tos/usecases/delete_competency.dart';
import 'package:likha/domain/tos/usecases/delete_tos.dart';
import 'package:likha/domain/tos/usecases/get_tos_detail.dart';
import 'package:likha/domain/tos/usecases/get_tos_list.dart';
import 'package:likha/domain/tos/usecases/search_melcs.dart';
import 'package:likha/domain/tos/usecases/update_competency.dart';
import 'package:likha/domain/tos/usecases/update_tos.dart';
import 'package:likha/presentation/providers/tos_provider.dart';

import '../../../helpers/fake_entities.dart';

// ── Mocks ─────────────────────────────────────────────────────────────────────

class MockGetTosList extends Mock implements GetTosList {}
class MockGetTosDetail extends Mock implements GetTosDetail {}
class MockCreateTos extends Mock implements CreateTos {}
class MockUpdateTos extends Mock implements UpdateTos {}
class MockDeleteTos extends Mock implements DeleteTos {}
class MockAddCompetency extends Mock implements AddCompetency {}
class MockUpdateCompetency extends Mock implements UpdateCompetency {}
class MockDeleteCompetency extends Mock implements DeleteCompetency {}
class MockBulkAddCompetencies extends Mock implements BulkAddCompetencies {}
class MockSearchMelcs extends Mock implements SearchMelcs {}

// ── Helpers ───────────────────────────────────────────────────────────────────

late MockGetTosList _mockGetTosList;
late MockCreateTos _mockCreateTos;
late MockDeleteTos _mockDeleteTos;

void _registerGetIt() {
  final sl = GetIt.instance;
  _mockGetTosList = MockGetTosList();
  _mockCreateTos = MockCreateTos();
  _mockDeleteTos = MockDeleteTos();

  sl.registerSingleton<GetTosList>(_mockGetTosList);
  sl.registerSingleton<GetTosDetail>(MockGetTosDetail());
  sl.registerSingleton<CreateTos>(_mockCreateTos);
  sl.registerSingleton<UpdateTos>(MockUpdateTos());
  sl.registerSingleton<DeleteTos>(_mockDeleteTos);
  sl.registerSingleton<AddCompetency>(MockAddCompetency());
  sl.registerSingleton<UpdateCompetency>(MockUpdateCompetency());
  sl.registerSingleton<DeleteCompetency>(MockDeleteCompetency());
  sl.registerSingleton<BulkAddCompetencies>(MockBulkAddCompetencies());
  sl.registerSingleton<SearchMelcs>(MockSearchMelcs());
}

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  final tTos = FakeEntities.tos();

  setUp(() {
    _registerGetIt();
  });

  tearDown(() async {
    await GetIt.instance.reset();
  });

  group('TosNotifier', () {
    group('loadTosList', () {
      test('populates tosList on success', () async {
        when(() => _mockGetTosList.call(any()))
            .thenAnswer((_) async => Right([tTos]));

        final notifier = TosNotifier();
        final states = <TosState>[];
        notifier.addListener((s) => states.add(s), fireImmediately: false);

        await notifier.loadTosList('c-1');

        expect(states.last.isLoading, isFalse);
        expect(states.last.tosList.length, 1);
        expect(states.last.error, isNull);
      });

      test('sets error on failure', () async {
        when(() => _mockGetTosList.call(any()))
            .thenAnswer((_) async => const Left(ServerFailure('error')));

        final notifier = TosNotifier();
        final states = <TosState>[];
        notifier.addListener((s) => states.add(s), fireImmediately: false);

        await notifier.loadTosList('c-1');

        expect(states.last.isLoading, isFalse);
        expect(states.last.error, isNotNull);
        expect(states.last.tosList, isEmpty);
      });
    });

    group('createTos', () {
      test('prepends created TOS and sets success message', () async {
        when(() => _mockCreateTos.call(
              classId: any(named: 'classId'),
              data: any(named: 'data'),
            )).thenAnswer((_) async => Right(tTos));

        final notifier = TosNotifier();
        final states = <TosState>[];
        notifier.addListener((s) => states.add(s), fireImmediately: false);

        final result = await notifier.createTos('c-1', {
          'title': 'Q1 TOS',
          'grading_period_number': 1,
          'classification_mode': 'difficulty',
          'total_items': 40,
        });

        expect(result, isNotNull);
        expect(states.last.tosList.first.id, tTos.id);
        expect(states.last.successMessage, isNotNull);
        expect(states.last.error, isNull);
      });

      test('sets error when create fails', () async {
        when(() => _mockCreateTos.call(
              classId: any(named: 'classId'),
              data: any(named: 'data'),
            )).thenAnswer((_) async => const Left(ServerFailure('create failed')));

        final notifier = TosNotifier();
        final states = <TosState>[];
        notifier.addListener((s) => states.add(s), fireImmediately: false);

        final result = await notifier.createTos('c-1', {});

        expect(result, isNull);
        expect(states.last.error, isNotNull);
      });
    });

    group('deleteTos', () {
      test('removes TOS from list on success', () async {
        when(() => _mockGetTosList.call(any()))
            .thenAnswer((_) async => Right([tTos]));
        when(() => _mockDeleteTos.call(any()))
            .thenAnswer((_) async => const Right(null));

        final notifier = TosNotifier();
        notifier.state = notifier.state.copyWith(tosList: [tTos]);

        final states = <TosState>[];
        notifier.addListener((s) => states.add(s), fireImmediately: false);

        await notifier.deleteTos(tTos.id);

        expect(states.last.tosList, isEmpty);
        expect(states.last.successMessage, isNotNull);
      });
    });
  });
}
