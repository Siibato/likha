import 'dart:convert';

import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:likha/core/database/db_schema.dart';
import 'package:likha/core/database/local_database.dart';
import 'package:likha/core/errors/failures.dart';
import 'package:likha/core/sync/mutation_result.dart';
import 'package:likha/core/sync/sync_queue.dart';
import 'package:likha/data/datasources/local/grading/grading_local_datasource.dart';
import 'package:likha/data/models/grading/grade_config_model.dart';
import 'package:likha/data/models/grading/grade_item_model.dart';
import 'package:likha/data/models/grading/grade_score_model.dart';
import 'package:likha/data/models/grading/period_grade_model.dart';
import 'package:likha/data/repositories/grading/operations/clear_score_override.dart';
import 'package:likha/data/repositories/grading/operations/create_grade_item.dart';
import 'package:likha/data/repositories/grading/operations/delete_grade_item.dart';
import 'package:likha/data/repositories/grading/operations/save_scores.dart';
import 'package:likha/data/repositories/grading/operations/set_score_override.dart';
import 'package:likha/data/repositories/grading/operations/setup_grading.dart';
import 'package:likha/data/repositories/grading/operations/update_grade_item.dart';
import 'package:likha/data/repositories/grading/operations/update_grading_config.dart';
import 'package:likha/data/repositories/grading/operations/update_transmuted_grade.dart';

import '../../../../../helpers/test_database.dart';

// ─── Helpers ───────────────────────────────────────────────────────────────────

GradeConfigModel _fakeConfig({
  String id = 'config-1',
  String classId = 'class-1',
  int gradingPeriodNumber = 1,
}) {
  final now = DateTime.now().toIso8601String();
  return GradeConfigModel(
    id: id,
    classId: classId,
    gradingPeriodNumber: gradingPeriodNumber,
    wwWeight: 30.0,
    ptWeight: 50.0,
    qaWeight: 20.0,
    createdAt: now,
    updatedAt: now,
  );
}

GradeItemModel _fakeItem({
  String id = 'item-1',
  String classId = 'class-1',
  String title = 'Test Item',
  String component = 'ww',
  int gradingPeriodNumber = 1,
  double totalPoints = 100.0,
}) {
  final now = DateTime.now();
  return GradeItemModel(
    id: id,
    classId: classId,
    title: title,
    component: component,
    gradingPeriodNumber: gradingPeriodNumber,
    totalPoints: totalPoints,
    sourceType: 'manual',
    orderIndex: 0,
    createdAt: now,
    updatedAt: now,
  );
}

GradeScoreModel _fakeScore({
  String id = 'score-1',
  String gradeItemId = 'item-1',
  String studentId = 'student-1',
  double? score = 85.0,
  double? overrideScore,
}) {
  final now = DateTime.now().toIso8601String();
  return GradeScoreModel(
    id: id,
    gradeItemId: gradeItemId,
    studentId: studentId,
    score: score,
    isAutoPopulated: false,
    overrideScore: overrideScore,
    createdAt: now,
    updatedAt: now,
  );
}

PeriodGradeModel _fakePeriodGrade({
  String id = 'pg-1',
  String classId = 'class-1',
  String studentId = 'student-1',
  int gradingPeriodNumber = 1,
}) {
  final now = DateTime.now();
  return PeriodGradeModel(
    id: id,
    classId: classId,
    studentId: studentId,
    gradingPeriodNumber: gradingPeriodNumber,
    initialGrade: 85.0,
    transmutedGrade: 85,
    isLocked: false,
    computedAt: now,
    createdAt: now,
    updatedAt: now,
  );
}

Future<void> _seedConfig(GradingLocalDataSource local, GradeConfigModel c) async {
  await local.saveConfigs([c]);
}

Future<void> _seedItem(GradingLocalDataSource local, GradeItemModel item) async {
  await local.saveItems([item]);
}

Future<void> _seedScore(GradingLocalDataSource local, GradeScoreModel score) async {
  await local.saveScores([score]);
}

Future<void> _seedPeriodGrade(GradingLocalDataSource local, PeriodGradeModel pg) async {
  await local.savePeriodGrades([pg]);
}

Future<List<Map<String, dynamic>>> _getSyncQueueRows() async {
  final db = await LocalDatabase().database;
  return db.query(DbTables.syncQueue);
}

Future<Map<String, dynamic>?> _getItemRow(String id) async {
  final db = await LocalDatabase().database;
  final rows = await db.query(
    DbTables.gradeItems,
    where: '${CommonCols.id} = ?',
    whereArgs: [id],
  );
  return rows.isEmpty ? null : rows.first;
}

Future<Map<String, dynamic>?> _getScoreRow(String id) async {
  final db = await LocalDatabase().database;
  final rows = await db.query(
    DbTables.gradeScores,
    where: '${CommonCols.id} = ?',
    whereArgs: [id],
  );
  return rows.isEmpty ? null : rows.first;
}

Future<Map<String, dynamic>?> _getPeriodGradeRow(String id) async {
  final db = await LocalDatabase().database;
  final rows = await db.query(
    DbTables.periodGrades,
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
    expect(row[SyncQueueCols.status], SyncStatus.pending.dbValue);
  }
}

// ─── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  late GradingLocalDataSourceImpl local;
  late SyncQueueImpl syncQueue;

  setUp(() async {
    await openFreshTestDatabase();
    syncQueue = SyncQueueImpl(LocalDatabase());
    local = GradingLocalDataSourceImpl(LocalDatabase(), syncQueue);
  });

  tearDown(() async {
    await closeTestDatabase();
  });

  group('setupGrading', () {
    test('returns MutationResult<List<GradeConfig>> with pending and enqueues setup op', () async {
      final result = await setupGrading(
        local,
        syncQueue,
        classId: 'class-1',
        gradeLevel: '7',
        subjectGroup: 'language',
        schoolYear: '2025-2026',
      );

      _assertMutationResult(result);
      final entities = result.getOrElse(() => throw 'Expected Right').entity;
      expect(entities.length, 4);

      final queue = await _getSyncQueueRows();
      _assertSyncQueueEntry(queue, count: 1, entityType: SyncEntityType.gradeConfig, operation: SyncOperation.setup);
      final payload = _decodePayload(queue.first);
      expect(payload['class_id'], 'class-1');
    });
  });

  group('updateGradingConfig', () {
    test('returns MutationResult<void> with pending and enqueues update op', () async {
      await _seedConfig(local, _fakeConfig(id: 'c1'));

      final result = await updateGradingConfig(
        local,
        syncQueue,
        classId: 'class-1',
        configs: [
          {'id': 'c1', 'quarter': 1, 'ww_weight': 35.0, 'pt_weight': 45.0, 'qa_weight': 20.0},
        ],
      );

      _assertMutationResult(result);

      final queue = await _getSyncQueueRows();
      _assertSyncQueueEntry(queue, count: 1, entityType: SyncEntityType.gradeConfig, operation: SyncOperation.update);
    });
  });

  group('createGradeItem', () {
    test('returns MutationResult<GradeItem> with pending and enqueues create op', () async {
      final result = await createGradeItem(
        local,
        syncQueue,
        classId: 'class-1',
        data: {
          'title': 'New Item',
          'component': 'ww',
          'grading_period_number': 1,
          'total_points': 50.0,
          'order_index': 0,
        },
      );

      _assertMutationResult(result);
      final entity = result.getOrElse(() => throw 'Expected Right').entity;
      expect(entity.title, 'New Item');

      final row = await _getItemRow(entity.id);
      expect(row, isNotNull);
      expect(row![GradeItemsCols.title], 'New Item');
      expect(row[CommonCols.syncStatus], SyncStatus.pending.dbValue);

      final queue = await _getSyncQueueRows();
      _assertSyncQueueEntry(queue, count: 1, entityType: SyncEntityType.gradeItem, operation: SyncOperation.create);
    });
  });

  group('updateGradeItem', () {
    test('returns MutationResult<void> with pending and enqueues update op', () async {
      await _seedItem(local, _fakeItem(id: 'i1', title: 'Old Title'));

      final result = await updateGradeItem(
        local,
        syncQueue,
        id: 'i1',
        data: {'title': 'New Title'},
      );

      _assertMutationResult(result);

      final row = await _getItemRow('i1');
      expect(row![GradeItemsCols.title], 'New Title');
      expect(row[CommonCols.syncStatus], SyncStatus.pending.dbValue);

      final queue = await _getSyncQueueRows();
      _assertSyncQueueEntry(queue, count: 1, entityType: SyncEntityType.gradeItem, operation: SyncOperation.update);
      final payload = _decodePayload(queue.first);
      expect(payload['id'], 'i1');
    });
  });

  group('deleteGradeItem', () {
    test('returns MutationResult<void> with pending, soft-deletes and enqueues delete op', () async {
      await _seedItem(local, _fakeItem(id: 'i1'));

      final result = await deleteGradeItem(
        local,
        syncQueue,
        id: 'i1',
      );

      _assertMutationResult(result);

      final row = await _getItemRow('i1');
      expect(row![CommonCols.deletedAt], isNotNull);

      final queue = await _getSyncQueueRows();
      _assertSyncQueueEntry(queue, count: 1, entityType: SyncEntityType.gradeItem, operation: SyncOperation.delete);
      final payload = _decodePayload(queue.first);
      expect(payload['id'], 'i1');
    });
  });

  group('saveScores', () {
    test('returns MutationResult<void> with pending and enqueues save_scores op', () async {
      await _seedItem(local, _fakeItem(id: 'item-1'));

      final result = await saveScores(
        local,
        gradeItemId: 'item-1',
        scores: [
          {'student_id': 'student-1', 'score': 85.0},
          {'student_id': 'student-2', 'score': 90.0},
        ],
      );

      _assertMutationResult(result);

      final queue = await _getSyncQueueRows();
      _assertSyncQueueEntry(queue, count: 1, entityType: SyncEntityType.gradeScore, operation: SyncOperation.saveScores);
      final payload = _decodePayload(queue.first);
      expect(payload['grade_item_id'], 'item-1');
    });
  });

  group('setScoreOverride', () {
    test('returns MutationResult<void> with pending and enqueues set_override op', () async {
      await _seedItem(local, _fakeItem(id: 'item-1'));
      await _seedScore(local, _fakeScore(id: 's1', gradeItemId: 'item-1'));

      final result = await setScoreOverride(
        local,
        syncQueue,
        scoreId: 's1',
        overrideScore: 95.0,
      );

      _assertMutationResult(result);

      final row = await _getScoreRow('s1');
      expect(row![GradeScoresCols.overrideScore], 95.0);
      expect(row[CommonCols.syncStatus], SyncStatus.pending.dbValue);

      final queue = await _getSyncQueueRows();
      _assertSyncQueueEntry(queue, count: 1, entityType: SyncEntityType.gradeScore, operation: SyncOperation.setOverride);
      final payload = _decodePayload(queue.first);
      expect(payload['score_id'], 's1');
    });
  });

  group('clearScoreOverride', () {
    test('returns MutationResult<void> with pending and enqueues clear_override op', () async {
      await _seedItem(local, _fakeItem(id: 'item-1'));
      await _seedScore(local, _fakeScore(id: 's1', gradeItemId: 'item-1', overrideScore: 95.0));

      final result = await clearScoreOverride(
        local,
        syncQueue,
        scoreId: 's1',
      );

      _assertMutationResult(result);

      final row = await _getScoreRow('s1');
      expect(row![GradeScoresCols.overrideScore], isNull);
      expect(row[CommonCols.syncStatus], SyncStatus.pending.dbValue);

      final queue = await _getSyncQueueRows();
      _assertSyncQueueEntry(queue, count: 1, entityType: SyncEntityType.gradeScore, operation: SyncOperation.clearOverride);
      final payload = _decodePayload(queue.first);
      expect(payload['score_id'], 's1');
    });
  });

  group('updateTransmutedGrade', () {
    test('returns MutationResult<void> with pending and enqueues update op', () async {
      await _seedPeriodGrade(local, _fakePeriodGrade(id: 'pg1'));

      final result = await updateTransmutedGrade(
        local,
        syncQueue,
        classId: 'class-1',
        studentId: 'student-1',
        gradingPeriodNumber: 1,
        transmutedGrade: 90,
      );

      _assertMutationResult(result);

      final row = await _getPeriodGradeRow('pg1');
      expect(row![PeriodGradesCols.transmutedGrade], 90);
      expect(row[CommonCols.syncStatus], SyncStatus.pending.dbValue);

      final queue = await _getSyncQueueRows();
      _assertSyncQueueEntry(queue, count: 1, entityType: SyncEntityType.gradeScore, operation: SyncOperation.update);
      final payload = _decodePayload(queue.first);
      expect(payload['student_id'], 'student-1');
    });
  });
}
