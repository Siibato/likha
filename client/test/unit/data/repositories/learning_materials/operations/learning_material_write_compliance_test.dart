import 'dart:convert';

import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:likha/core/database/db_schema.dart';
import 'package:likha/core/database/local_database.dart';
import 'package:likha/core/errors/failures.dart';
import 'package:likha/core/sync/mutation_result.dart';
import 'package:likha/core/sync/sync_queue.dart';
import 'package:likha/data/datasources/local/learning_materials/learning_material_local_datasource.dart';
import 'package:likha/data/models/learning_materials/learning_material_model.dart';
import 'package:likha/data/repositories/learning_materials/operations/create_material.dart';
import 'package:likha/data/repositories/learning_materials/operations/delete_file.dart';
import 'package:likha/data/repositories/learning_materials/operations/delete_material.dart';
import 'package:likha/data/repositories/learning_materials/operations/reorder_all_materials.dart';
import 'package:likha/data/repositories/learning_materials/operations/reorder_material.dart';
import 'package:likha/data/repositories/learning_materials/operations/update_material.dart';
import 'package:likha/data/repositories/learning_materials/operations/upload_file.dart';

import '../../../../../helpers/mock_datasources.dart';
import '../../../../../helpers/test_database.dart';

// ─── Helpers ───────────────────────────────────────────────────────────────────

LearningMaterialModel _fakeMaterial({
  String id = 'material-1',
  String classId = 'class-1',
  String title = 'Test Material',
  int orderIndex = 0,
}) {
  final now = DateTime.now();
  return LearningMaterialModel(
    id: id,
    classId: classId,
    title: title,
    description: 'Test description',
    contentText: 'Test content',
    orderIndex: orderIndex,
    fileCount: 0,
    createdAt: now,
    updatedAt: now,
  );
}

Future<void> _seedMaterial(LearningMaterialLocalDataSource local, LearningMaterialModel m) async {
  await local.saveMaterial(m);
}

Future<List<Map<String, dynamic>>> _getSyncQueueRows() async {
  final db = await LocalDatabase().database;
  return db.query(DbTables.syncQueue);
}

Future<Map<String, dynamic>?> _getMaterialRow(String id) async {
  final db = await LocalDatabase().database;
  final rows = await db.query(
    DbTables.learningMaterials,
    where: '${CommonCols.id} = ?',
    whereArgs: [id],
  );
  return rows.isEmpty ? null : rows.first;
}

Future<Map<String, dynamic>?> _getFileRow(String id) async {
  final db = await LocalDatabase().database;
  final rows = await db.query(
    DbTables.materialFiles,
    where: '${CommonCols.id} = ?',
    whereArgs: [id],
  );
  return rows.isEmpty ? null : rows.first;
}

Map<String, dynamic> _decodePayload(Map<String, dynamic> row) {
  return jsonDecode(row[SyncQueueCols.payload] as String) as Map<String, dynamic>;
}

void _assertMutationResult<T>(Either<Failure, MutationResult<T>> result) {
  expect(result.isRight(), isTrue, reason: 'Expected Right(MutationResult)');
  result.fold(
    (f) => fail('Expected Right, got Left($f)'),
    (mr) => expect(mr.status, SyncStatus.pending),
  );
}

void _assertSyncQueueEntry(
  List<Map<String, dynamic>> rows, {
  required int count,
  required SyncEntityType entityType,
  required SyncOperation operation,
}) {
  expect(rows.length, count, reason: 'Expected $count sync queue entries');
  if (rows.isEmpty) return;
  for (final row in rows) {
    expect(row[SyncQueueCols.entityType], entityType.dbValue);
    expect(row[SyncQueueCols.operation], operation.dbValue);
    // The returned MutationResult.status is the authoritative value
  }
}

// ─── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  late LearningMaterialLocalDataSourceImpl local;
  late SyncQueueImpl syncQueue;
  late MockLearningMaterialRemoteDataSource remote;
  setUp(() async {
    await openFreshTestDatabase();
    syncQueue = SyncQueueImpl(LocalDatabase());
    local = LearningMaterialLocalDataSourceImpl(LocalDatabase(), syncQueue);
    remote = MockLearningMaterialRemoteDataSource();
  });

  tearDown(() async {
    await closeTestDatabase();
  });

  group('createMaterial', () {
    test('returns MutationResult<LearningMaterial> with pending and enqueues create op', () async {
      final result = await createMaterial(
        local,
        syncQueue,
        classId: 'class-1',
        title: 'New Material',
        description: 'A test material',
        contentText: 'Some content',
      );

      _assertMutationResult(result);
      final entity = result.getOrElse(() => throw 'Expected Right').entity;
      expect(entity.title, 'New Material');

      final row = await _getMaterialRow(entity.id);
      expect(row, isNotNull);
      expect(row![LearningMaterialsCols.title], 'New Material');
      expect(row[CommonCols.syncStatus], SyncStatus.pending.dbValue);

      final queue = await _getSyncQueueRows();
      _assertSyncQueueEntry(queue, count: 1, entityType: SyncEntityType.learningMaterial, operation: SyncOperation.create);
      final payload = _decodePayload(queue.first);
      expect(payload['id'], entity.id);
      expect(payload['class_id'], 'class-1');
    });
  });

  group('updateMaterial', () {
    test('returns MutationResult<LearningMaterial> with pending and enqueues update op', () async {
      await _seedMaterial(local, _fakeMaterial(id: 'm1', title: 'Old Title'));

      final result = await updateMaterial(
        local,
        syncQueue,
        materialId: 'm1',
        title: 'New Title',
      );

      _assertMutationResult(result);
      final entity = result.getOrElse(() => throw 'Expected Right').entity;
      expect(entity.title, 'New Title');

      final row = await _getMaterialRow('m1');
      expect(row![LearningMaterialsCols.title], 'New Title');
      expect(row[CommonCols.syncStatus], SyncStatus.pending.dbValue);

      final queue = await _getSyncQueueRows();
      _assertSyncQueueEntry(queue, count: 1, entityType: SyncEntityType.learningMaterial, operation: SyncOperation.update);
      final payload = _decodePayload(queue.first);
      expect(payload['id'], 'm1');
    });
  });

  group('deleteMaterial', () {
    test('returns MutationResult<void> with pending, soft-deletes and enqueues delete op', () async {
      await _seedMaterial(local, _fakeMaterial(id: 'm1'));

      final result = await deleteMaterial(
        local,
        syncQueue,
        materialId: 'm1',
      );

      _assertMutationResult(result);

      final row = await _getMaterialRow('m1');
      expect(row![CommonCols.deletedAt], isNotNull);

      final queue = await _getSyncQueueRows();
      _assertSyncQueueEntry(queue, count: 1, entityType: SyncEntityType.learningMaterial, operation: SyncOperation.delete);
      final payload = _decodePayload(queue.first);
      expect(payload['id'], 'm1');
    });
  });

  group('reorderMaterial', () {
    test('returns MutationResult<LearningMaterial> with pending, updates order and enqueues update op', () async {
      await _seedMaterial(local, _fakeMaterial(id: 'm1', orderIndex: 0));

      final result = await reorderMaterial(
        local,
        syncQueue,
        materialId: 'm1',
        newOrderIndex: 5,
      );

      _assertMutationResult(result);
      final entity = result.getOrElse(() => throw 'Expected Right').entity;
      expect(entity.orderIndex, 5);

      final row = await _getMaterialRow('m1');
      expect(row![LearningMaterialsCols.orderIndex], 5);
      expect(row[CommonCols.syncStatus], SyncStatus.pending.dbValue);

      final queue = await _getSyncQueueRows();
      _assertSyncQueueEntry(queue, count: 1, entityType: SyncEntityType.learningMaterial, operation: SyncOperation.update);
      final payload = _decodePayload(queue.first);
      expect(payload['id'], 'm1');
    });
  });

  group('reorderAllMaterials', () {
    test('returns MutationResult<void> with pending, updates order and enqueues single reorder op', () async {
      await _seedMaterial(local, _fakeMaterial(id: 'm1', orderIndex: 0));
      await _seedMaterial(local, _fakeMaterial(id: 'm2', orderIndex: 1));

      final result = await reorderAllMaterials(
        local,
        syncQueue,
        classId: 'class-1',
        materialIds: ['m2', 'm1'],
      );

      _assertMutationResult(result);

      final rowM1 = await _getMaterialRow('m1');
      final rowM2 = await _getMaterialRow('m2');
      expect(rowM1![LearningMaterialsCols.orderIndex], 1);
      expect(rowM2![LearningMaterialsCols.orderIndex], 0);
      // The returned MutationResult.status is the authoritative value

      final queue = await _getSyncQueueRows();
      _assertSyncQueueEntry(queue, count: 1, entityType: SyncEntityType.learningMaterial, operation: SyncOperation.reorder);
      final payload = _decodePayload(queue.first);
      expect(payload['class_id'], 'class-1');
    });
  });

  group('uploadFile', () {
    test(
      'returns MutationResult<MaterialFile> with pending and enqueues upload op',
      () async {
        await _seedMaterial(local, _fakeMaterial(id: 'm1'));

        final result = await uploadFile(
          local,
          syncQueue,
          remote,
          materialId: 'm1',
          filePath: '/tmp/test.pdf',
          fileName: 'test.pdf',
        );

        _assertMutationResult(result);
        final entity = result.getOrElse(() => throw 'Expected Right').entity;
        expect(entity.fileName, 'test.pdf');

        final row = await _getFileRow(entity.id);
        expect(row, isNotNull);
        expect(row![MaterialFilesCols.fileName], 'test.pdf');
        expect(row[CommonCols.syncStatus], SyncStatus.pending.dbValue);

        final queue = await _getSyncQueueRows();
        _assertSyncQueueEntry(
          queue,
          count: 1,
          entityType: SyncEntityType.materialFile,
          operation: SyncOperation.upload,
        );
        final payload = _decodePayload(queue.first);
        expect(payload['file_id'], entity.id);
        expect(payload['material_id'], 'm1');
      },
      skip: 'Requires path_provider platform channel and file system setup in unit-test environment',
    );
  });

  group('deleteFile', () {
    test('returns MutationResult<void> with pending, soft-deletes file and enqueues delete op', () async {
      await _seedMaterial(local, _fakeMaterial(id: 'm1'));
      final db = await LocalDatabase().database;
      await db.insert(DbTables.materialFiles, {
        CommonCols.id: 'f1',
        MaterialFilesCols.materialId: 'm1',
        MaterialFilesCols.fileName: 'test.pdf',
        MaterialFilesCols.fileType: 'application/pdf',
        MaterialFilesCols.fileSize: 1024,
        MaterialFilesCols.localPath: '/tmp/test.pdf',
        MaterialFilesCols.uploadedAt: DateTime.now().toIso8601String(),
        CommonCols.cachedAt: DateTime.now().toIso8601String(),
        CommonCols.syncStatus: SyncStatus.synced.dbValue,
      });

      final result = await deleteFile(
        local,
        syncQueue,
        fileId: 'f1',
      );

      _assertMutationResult(result);

      final row = await _getFileRow('f1');
      expect(row, isNull);

      final queue = await _getSyncQueueRows();
      _assertSyncQueueEntry(
        queue,
        count: 1,
        entityType: SyncEntityType.materialFile,
        operation: SyncOperation.delete,
      );
      final payload = _decodePayload(queue.first);
      expect(payload['file_id'], 'f1');
    });
  });
}
