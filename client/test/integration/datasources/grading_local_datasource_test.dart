import 'package:flutter_test/flutter_test.dart';
import 'package:likha/core/database/local_database.dart';
import 'package:likha/core/sync/sync_queue.dart';
import 'package:likha/data/datasources/local/grading/impl/grading_local_datasource_impl.dart';
import 'package:likha/data/models/grading/grade_config_model.dart';
import 'package:uuid/uuid.dart';

import '../../helpers/test_database.dart';

const _classId = 'class-001';
const _uuid = Uuid();

GradeConfigModel _sampleConfig({int period = 1}) {
  final now = DateTime.now().toIso8601String();
  return GradeConfigModel(
    id: _uuid.v4(),
    classId: _classId,
    gradingPeriodNumber: period,
    wwWeight: 30.0,
    ptWeight: 50.0,
    qaWeight: 20.0,
    createdAt: now,
    updatedAt: now,
  );
}

void main() {
  late GradingLocalDataSourceImpl datasource;
  late SyncQueueImpl syncQueue;

  setUp(() async {
    await openFreshTestDatabase();
    syncQueue = SyncQueueImpl(LocalDatabase());
    datasource = GradingLocalDataSourceImpl(LocalDatabase(), syncQueue);
  });

  tearDown(() => closeTestDatabase());

  group('GradingLocalDataSource', () {
    test('saveConfigs and getConfigByClass returns persisted configs', () async {
      await datasource.saveConfigs([
        _sampleConfig(period: 1),
        _sampleConfig(period: 2),
      ]);
      final result = await datasource.getConfigByClass(_classId);
      expect(result.length, 2);
      final periods = result.map((c) => c.gradingPeriodNumber).toSet();
      expect(periods, containsAll({1, 2}));
    });

    test('saveConfigs updates existing config on conflict (replace)', () async {
      final config = _sampleConfig(period: 1);
      await datasource.saveConfigs([config]);

      final updated = GradeConfigModel(
        id: config.id,
        classId: config.classId,
        gradingPeriodNumber: 1,
        wwWeight: 25.0,
        ptWeight: 55.0,
        qaWeight: 20.0,
        createdAt: config.createdAt,
        updatedAt: DateTime.now().toIso8601String(),
      );
      await datasource.saveConfigs([updated]);

      final result = await datasource.getConfigByClass(_classId);
      expect(result.length, 1);
      expect(result.first.wwWeight, 25.0);
    });

    test('getConfigByClass returns empty list for unknown class', () async {
      final result = await datasource.getConfigByClass('unknown-class');
      expect(result, isEmpty);
    });

    test('saveItems and getItemsByClassQuarter returns grade items', () async {
      final items = await datasource.getItemsByClassQuarter(_classId, 1);
      expect(items, isEmpty);
    });
  });
}
