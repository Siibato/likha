import 'dart:convert';

import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_sqlcipher/sqflite.dart';
import 'package:likha/core/database/db_schema.dart';
import 'package:likha/core/database/local_database.dart';
import 'package:likha/core/errors/failures.dart';
import 'package:likha/core/sync/mutation_result.dart';
import 'package:likha/core/sync/sync_queue.dart';
import 'package:likha/data/datasources/local/tos/tos_local_datasource.dart';
import 'package:likha/data/models/tos/tos_model.dart';
import 'package:likha/data/repositories/tos/operations/add_competency.dart';
import 'package:likha/data/repositories/tos/operations/bulk_add_competencies.dart';
import 'package:likha/data/repositories/tos/operations/create_tos.dart';
import 'package:likha/data/repositories/tos/operations/delete_competency.dart';
import 'package:likha/data/repositories/tos/operations/delete_tos.dart';
import 'package:likha/data/repositories/tos/operations/update_competency.dart';
import 'package:likha/data/repositories/tos/operations/update_tos.dart';

import '../../../../../helpers/test_database.dart';

// ─── Helpers ───────────────────────────────────────────────────────────────────

TosModel _fakeTos({
  String id = 'tos-1',
  String classId = 'class-1',
  String title = 'Test TOS',
  int termNumber = 1,
}) {
  final now = DateTime.now();
  return TosModel(
    id: id,
    classId: classId,
    termNumber: termNumber,
    title: title,
    classificationMode: 'cognitive',
    totalItems: 50,
    createdAt: now,
    updatedAt: now,
  );
}

CompetencyModel _fakeCompetency({
  String id = 'comp-1',
  String tosId = 'tos-1',
  String text = 'Test Competency',
  int orderIndex = 0,
}) {
  final now = DateTime.now();
  return CompetencyModel(
    id: id,
    tosId: tosId,
    competencyText: text,
    timeUnitsTaught: 5,
    orderIndex: orderIndex,
    createdAt: now,
    updatedAt: now,
  );
}

Future<void> _seedTos(TosLocalDataSource local, TosModel tos) async {
  final db = await LocalDatabase().database;
  await db.insert(
    DbTables.tableOfSpecifications,
    {
      ...tos.toMap(),
      CommonCols.syncStatus: SyncStatus.synced.dbValue,
    },
    conflictAlgorithm: ConflictAlgorithm.replace,
  );
}

Future<void> _seedCompetency(TosLocalDataSource local, CompetencyModel c) async {
  final db = await LocalDatabase().database;
  await db.insert(
    DbTables.tosCompetencies,
    {
      ...c.toMap(),
      CommonCols.syncStatus: SyncStatus.synced.dbValue,
    },
    conflictAlgorithm: ConflictAlgorithm.replace,
  );
}

Future<List<Map<String, dynamic>>> _getSyncQueueRows() async {
  final db = await LocalDatabase().database;
  return db.query(DbTables.syncQueue);
}

Future<Map<String, dynamic>?> _getTosRow(String id) async {
  final db = await LocalDatabase().database;
  final rows = await db.query(
    DbTables.tableOfSpecifications,
    where: '${CommonCols.id} = ?',
    whereArgs: [id],
  );
  return rows.isEmpty ? null : rows.first;
}

Future<Map<String, dynamic>?> _getCompetencyRow(String id) async {
  final db = await LocalDatabase().database;
  final rows = await db.query(
    DbTables.tosCompetencies,
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
    // Note: Don't check status in DB as fireRemoteWrite may update it asynchronously
    // The returned MutationResult.status is the authoritative value
  }
}

// ─── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  late TosLocalDataSourceImpl local;
  late SyncQueueImpl syncQueue;

  setUp(() async {
    await openFreshTestDatabase();
    syncQueue = SyncQueueImpl(LocalDatabase());
    local = TosLocalDataSourceImpl(LocalDatabase(), syncQueue);
  });

  tearDown(() async {
    await closeTestDatabase();
  });

  group('createTos', () {
    test('returns MutationResult<TableOfSpecifications> with pending and enqueues create op', () async {
      final result = await createTos(
        local,
        syncQueue,
        classId: 'class-1',
        data: {
          'term_number': 1,
          'title': 'New TOS',
          'classification_mode': 'cognitive',
          'total_items': 50,
        },
      );

      _assertMutationResult(result);
      final entity = result.getOrElse(() => throw 'Expected Right').entity;
      expect(entity.title, 'New TOS');

      final row = await _getTosRow(entity.id);
      expect(row, isNotNull);
      expect(row![TosCols.title], 'New TOS');
      expect(row[CommonCols.syncStatus], SyncStatus.pending.dbValue);

      final queue = await _getSyncQueueRows();
      _assertSyncQueueEntry(queue, count: 1, entityType: SyncEntityType.tableOfSpecifications, operation: SyncOperation.create);
      final payload = _decodePayload(queue.first);
      expect(payload['id'], entity.id);
      expect(payload['class_id'], 'class-1');
    });
  });

  group('updateTos', () {
    test('returns MutationResult<TableOfSpecifications> with pending and enqueues update op', () async {
      await _seedTos(local, _fakeTos(id: 't1', title: 'Old Title'));

      final result = await updateTos(
        local,
        syncQueue,
        tosId: 't1',
        data: {'title': 'New Title'},
      );

      _assertMutationResult(result);
      final entity = result.getOrElse(() => throw 'Expected Right').entity;
      expect(entity.title, 'New Title');

      final row = await _getTosRow('t1');
      expect(row![TosCols.title], 'New Title');
      expect(row[CommonCols.syncStatus], SyncStatus.pending.dbValue);

      final queue = await _getSyncQueueRows();
      _assertSyncQueueEntry(queue, count: 1, entityType: SyncEntityType.tableOfSpecifications, operation: SyncOperation.update);
      final payload = _decodePayload(queue.first);
      expect(payload['id'], 't1');
    });
  });

  group('deleteTos', () {
    test('returns MutationResult<void> with pending, soft-deletes and enqueues delete op', () async {
      await _seedTos(local, _fakeTos(id: 't1'));

      final result = await deleteTos(
        local,
        syncQueue,
        tosId: 't1',
      );

      _assertMutationResult(result);

      final row = await _getTosRow('t1');
      expect(row![CommonCols.deletedAt], isNotNull);

      final queue = await _getSyncQueueRows();
      _assertSyncQueueEntry(queue, count: 1, entityType: SyncEntityType.tableOfSpecifications, operation: SyncOperation.delete);
      final payload = _decodePayload(queue.first);
      expect(payload['id'], 't1');
    });
  });

  group('addCompetency', () {
    test('returns MutationResult<TosCompetency> with pending and enqueues create op', () async {
      await _seedTos(local, _fakeTos(id: 't1'));

      final result = await addCompetency(
        local,
        syncQueue,
        tosId: 't1',
        data: {
          'competency_text': 'New Competency',
          'time_units_taught': 5,
        },
      );

      _assertMutationResult(result);
      final entity = result.getOrElse(() => throw 'Expected Right').entity;
      expect(entity.competencyText, 'New Competency');

      final queue = await _getSyncQueueRows();
      _assertSyncQueueEntry(queue, count: 1, entityType: SyncEntityType.tosCompetency, operation: SyncOperation.create);
      final payload = _decodePayload(queue.first);
      expect(payload['tos_id'], 't1');
    });
  });

  group('updateCompetency', () {
    test('returns MutationResult<TosCompetency> with pending and enqueues update op', () async {
      await _seedTos(local, _fakeTos(id: 't1'));
      await _seedCompetency(local, _fakeCompetency(id: 'c1', tosId: 't1', text: 'Old Text'));

      final result = await updateCompetency(
        local,
        syncQueue,
        competencyId: 'c1',
        data: {'competency_text': 'New Text'},
      );

      _assertMutationResult(result);
      final entity = result.getOrElse(() => throw 'Expected Right').entity;
      expect(entity.competencyText, 'New Text');

      final row = await _getCompetencyRow('c1');
      expect(row![TosCompetenciesCols.competencyText], 'New Text');
      // Note: Don't check syncStatus in DB as fireRemoteWrite may update it asynchronously
      // The returned MutationResult.status is the authoritative value

      final queue = await _getSyncQueueRows();
      _assertSyncQueueEntry(queue, count: 1, entityType: SyncEntityType.tosCompetency, operation: SyncOperation.update);
      final payload = _decodePayload(queue.first);
      expect(payload['id'], 'c1');
    });
  });

  group('deleteCompetency', () {
    test('returns MutationResult<void> with pending, soft-deletes and enqueues delete op', () async {
      await _seedTos(local, _fakeTos(id: 't1'));
      await _seedCompetency(local, _fakeCompetency(id: 'c1', tosId: 't1'));

      final result = await deleteCompetency(
        local,
        syncQueue,
        competencyId: 'c1',
      );

      _assertMutationResult(result);

      final row = await _getCompetencyRow('c1');
      expect(row![CommonCols.deletedAt], isNotNull);

      final queue = await _getSyncQueueRows();
      _assertSyncQueueEntry(queue, count: 1, entityType: SyncEntityType.tosCompetency, operation: SyncOperation.delete);
      final payload = _decodePayload(queue.first);
      expect(payload['id'], 'c1');
    });
  });

  group('bulkAddCompetencies', () {
    test('returns MutationResult<List<TosCompetency>> with pending and enqueues create ops', () async {
      await _seedTos(local, _fakeTos(id: 't1'));

      final result = await bulkAddCompetencies(
        local,
        syncQueue,
        tosId: 't1',
        competencies: [
          {'competency_text': 'Comp 1', 'time_units_taught': 3},
          {'competency_text': 'Comp 2', 'time_units_taught': 4},
        ],
      );

      _assertMutationResult(result);
      final entities = result.getOrElse(() => throw 'Expected Right').entity;
      expect(entities.length, 2);

      final queue = await _getSyncQueueRows();
      _assertSyncQueueEntry(queue, count: 1, entityType: SyncEntityType.tosCompetency, operation: SyncOperation.create);
      final payload = _decodePayload(queue.first);
      expect(payload['tos_id'], 't1');
    });
  });
}
