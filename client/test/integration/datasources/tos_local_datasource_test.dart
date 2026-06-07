import 'package:flutter_test/flutter_test.dart';
import 'package:likha/core/database/local_database.dart';
import 'package:likha/core/sync/sync_queue.dart';
import 'package:likha/data/datasources/local/tos/impl/tos_local_datasource_impl.dart';
import 'package:likha/data/models/tos/tos_model.dart';

import '../../helpers/test_database.dart';

const _classId = 'class-001';
const _tosId = 'tos-001';

TosModel _sampleTos({String id = _tosId}) {
  final now = DateTime(2026, 4, 19);
  return TosModel(
    id: id,
    classId: _classId,
    gradingPeriodNumber: 1,
    title: 'TOS Q1',
    classificationMode: 'difficulty',
    totalItems: 30,
    createdAt: now,
    updatedAt: now,
  );
}

CompetencyModel _sampleCompetency({String id = 'comp-001'}) {
  final now = DateTime(2026, 4, 19);
  return CompetencyModel(
    id: id,
    tosId: _tosId,
    competencyText: 'Identify main ideas',
    timeUnitsTaught: 2,
    orderIndex: 0,
    createdAt: now,
    updatedAt: now,
  );
}

void main() {
  late TosLocalDataSourceImpl datasource;
  late SyncQueueImpl syncQueue;

  setUp(() async {
    await openFreshTestDatabase();
    syncQueue = SyncQueueImpl(LocalDatabase());
    datasource = TosLocalDataSourceImpl(LocalDatabase(), syncQueue);
  });

  tearDown(() => closeTestDatabase());

  group('TosLocalDataSource', () {
    test('cacheTosList and getTosByClass returns cached TOS list', () async {
      await datasource.cacheTosList([_sampleTos()]);
      final result = await datasource.getTosByClass(_classId);
      expect(result.length, 1);
      expect(result.first.id, _tosId);
      expect(result.first.title, 'TOS Q1');
    });

    test('getTosByClass returns empty list when nothing cached', () async {
      final result = await datasource.getTosByClass('unknown-class');
      expect(result, isEmpty);
    });

    test('cacheCompetencies and getCompetenciesByTos round-trips competency', () async {
      await datasource.cacheTosList([_sampleTos()]);
      await datasource.cacheCompetencies(_tosId, [_sampleCompetency()]);
      final result = await datasource.getCompetenciesByTos(_tosId);
      expect(result.length, 1);
      expect(result.first.id, 'comp-001');
      expect(result.first.competencyText, 'Identify main ideas');
    });

    test('getTosById returns correct TOS', () async {
      await datasource.cacheTosList([_sampleTos()]);
      final result = await datasource.getTosById(_tosId);
      expect(result, isNotNull);
      expect(result!.id, _tosId);
    });

    test('getTosById returns null for unknown id', () async {
      final result = await datasource.getTosById('no-such-id');
      expect(result, isNull);
    });
  });
}
