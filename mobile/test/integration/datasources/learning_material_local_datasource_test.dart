import 'package:flutter_test/flutter_test.dart';
import 'package:likha/core/database/db_schema.dart';
import 'package:likha/core/database/local_database.dart';
import 'package:likha/core/security/noop_encryption_service.dart';
import 'package:likha/core/sync/sync_queue.dart';
import 'package:likha/data/datasources/local/learning_materials/impl/learning_material_local_datasource_impl.dart';
import 'package:likha/data/models/learning_materials/learning_material_model.dart';

import '../../helpers/test_database.dart';

const _classId = 'class-001';

LearningMaterialModel _sampleMaterial({String id = 'material-001'}) {
  final now = DateTime(2026, 4, 19);
  return LearningMaterialModel(
    id: id,
    classId: _classId,
    title: 'Lesson 1',
    description: 'Introduction',
    contentText: 'Content here',
    orderIndex: 0,
    fileCount: 0,
    createdAt: now,
    updatedAt: now,
  );
}

void main() {
  late LearningMaterialLocalDataSourceImpl datasource;
  late SyncQueueImpl syncQueue;

  setUp(() async {
    await openFreshTestDatabase();
    syncQueue = SyncQueueImpl(LocalDatabase());
    datasource = LearningMaterialLocalDataSourceImpl(LocalDatabase(), syncQueue, const NoOpEncryptionService());
  });

  tearDown(() => closeTestDatabase());

  group('LearningMaterialLocalDataSource', () {
    test('cacheMaterials and getCachedMaterials returns list', () async {
      await datasource.cacheMaterials([_sampleMaterial()]);
      final result = await datasource.getCachedMaterials(_classId);
      expect(result.length, 1);
      expect(result.first.id, 'material-001');
      expect(result.first.title, 'Lesson 1');
    });

    test('createMaterialLocally inserts with needsSync=1', () async {
      final material = await datasource.createMaterialLocally(
        classId: _classId,
        title: 'New Lesson',
        description: 'A lesson',
        contentText: 'Body text',
      );
      expect(material.id, isNotEmpty);

      final db = await LocalDatabase().database;
      final rows = await db.query(
        DbTables.learningMaterials,
        where: '${CommonCols.id} = ?',
        whereArgs: [material.id],
      );
      expect(rows.length, 1);
      expect(rows.first['title'], 'New Lesson');
      expect(rows.first['needs_sync'], 1);
    });

    test('deleteMaterialLocally soft-deletes the material', () async {
      await datasource.cacheMaterials([_sampleMaterial()]);
      await datasource.deleteMaterialLocally('material-001');
      final result = await datasource.getCachedMaterials(_classId);
      expect(result, isEmpty);
    });

    test('getCachedMaterials returns empty list for unknown class', () async {
      final result = await datasource.getCachedMaterials('no-such-class');
      expect(result, isEmpty);
    });
  });
}
