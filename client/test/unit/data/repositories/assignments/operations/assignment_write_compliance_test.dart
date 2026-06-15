import 'dart:convert';

import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:likha/core/database/db_schema.dart';
import 'package:likha/core/database/local_database.dart';
import 'package:likha/core/errors/failures.dart';
import 'package:likha/core/sync/mutation_result.dart';
import 'package:likha/core/sync/sync_queue.dart';
import 'package:likha/data/datasources/local/assignments/assignment_local_datasource.dart';
import 'package:likha/data/models/assignments/assignment_model.dart';
import 'package:likha/data/models/assignments/assignment_submission_model.dart';
import 'package:likha/data/models/assignments/submission_file_model.dart';
import 'package:likha/data/repositories/assignments/operations/create_assignment.dart';
import 'package:likha/data/repositories/assignments/operations/create_submission.dart';
import 'package:likha/data/repositories/assignments/operations/delete_assignment.dart';
import 'package:likha/data/repositories/assignments/operations/delete_file.dart';
import 'package:likha/data/repositories/assignments/operations/grade_submission.dart';
import 'package:likha/data/repositories/assignments/operations/publish_assignment.dart';
import 'package:likha/data/repositories/assignments/operations/reorder_all_assignments.dart';
import 'package:likha/data/repositories/assignments/operations/return_submission.dart';
import 'package:likha/data/repositories/assignments/operations/submit_assignment.dart';
import 'package:likha/data/repositories/assignments/operations/unpublish_assignment.dart';
import 'package:likha/data/repositories/assignments/operations/update_assignment.dart';
import 'package:likha/data/repositories/assignments/operations/upload_file.dart';
import 'package:likha/services/storage_service.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../../helpers/test_database.dart';

class MockStorageService extends Mock implements StorageService {}

// ─── Helpers ───────────────────────────────────────────────────────────────────

AssignmentModel _fakeAssignment({
  String id = 'assignment-1',
  String classId = 'class-1',
  String title = 'Test Assignment',
  bool isPublished = false,
  int orderIndex = 0,
}) {
  final now = DateTime.now();
  return AssignmentModel(
    id: id,
    classId: classId,
    title: title,
    instructions: 'Test instructions',
    totalPoints: 100,
    allowsTextSubmission: true,
    allowsFileSubmission: false,
    dueAt: DateTime(2025, 12, 31),
    isPublished: isPublished,
    orderIndex: orderIndex,
    submissionCount: 0,
    gradedCount: 0,
    createdAt: now,
    updatedAt: now,
    syncStatus: SyncStatus.synced,
  );
}

AssignmentSubmissionModel _fakeSubmission({
  String id = 'submission-1',
  String assignmentId = 'assignment-1',
  String studentId = 'student-1',
  String status = 'draft',
}) {
  final now = DateTime.now();
  return AssignmentSubmissionModel(
    id: id,
    assignmentId: assignmentId,
    studentId: studentId,
    studentName: 'Test Student',
    status: status,
    files: const [],
    createdAt: now,
    updatedAt: now,
    syncStatus: SyncStatus.synced,
  );
}

SubmissionFileModel _fakeFile({
  String id = 'file-1',
  String submissionId = 'submission-1',
}) {
  final now = DateTime.now();
  return SubmissionFileModel(
    id: id,
    submissionId: submissionId,
    fileName: 'test.pdf',
    fileType: 'application/pdf',
    fileSize: 1024,
    uploadedAt: now,
    localPath: '/tmp/test.pdf',
    syncStatus: SyncStatus.synced,
  );
}

Future<void> _seedAssignment(AssignmentLocalDataSource local, AssignmentModel a) async {
  await local.cacheAssignmentDetail(a);
}

Future<void> _seedSubmission(AssignmentLocalDataSource local, AssignmentSubmissionModel s) async {
  await local.cacheSubmissionDetail(s);
}

Future<void> _seedFile(
  AssignmentLocalDataSource local,
  String submissionId,
  SubmissionFileModel f,
) async {
  await local.cacheSubmissionFile(submissionId, f);
}

Future<List<Map<String, dynamic>>> _getSyncQueueRows() async {
  final db = await LocalDatabase().database;
  return db.query(DbTables.syncQueue);
}

Future<Map<String, dynamic>?> _getAssignmentRow(String id) async {
  final db = await LocalDatabase().database;
  final rows = await db.query(
    DbTables.assignments,
    where: '${CommonCols.id} = ?',
    whereArgs: [id],
  );
  return rows.isEmpty ? null : rows.first;
}

Future<Map<String, dynamic>?> _getSubmissionRow(String id) async {
  final db = await LocalDatabase().database;
  final rows = await db.query(
    DbTables.assignmentSubmissions,
    where: '${CommonCols.id} = ?',
    whereArgs: [id],
  );
  return rows.isEmpty ? null : rows.first;
}

Future<Map<String, dynamic>?> _getFileRow(String id) async {
  final db = await LocalDatabase().database;
  final rows = await db.query(
    DbTables.submissionFiles,
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

// ─── Tests ───────────────────────────────────────────────────────────────────

void main() {
  late AssignmentLocalDataSourceImpl local;
  late SyncQueueImpl syncQueue;

  setUp(() async {
    await openFreshTestDatabase();
    syncQueue = SyncQueueImpl(LocalDatabase());
    local = AssignmentLocalDataSourceImpl(LocalDatabase(), syncQueue);
  });

  tearDown(() async {
    await closeTestDatabase();
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // Reference: createAssignment (already compliant)
  // ═══════════════════════════════════════════════════════════════════════════
  group('createAssignment (reference compliance)', () {
    test('returns MutationResult<Assignment> with pending and enqueues create op', () async {
      final result = await createAssignment(
        local,
        syncQueue,
        classId: 'class-1',
        title: 'New Assignment',
        instructions: 'Do this',
        totalPoints: 100,
        allowsTextSubmission: true,
        allowsFileSubmission: false,
        dueAt: '2025-12-31T00:00:00.000',
        isPublished: true,
      );

      _assertMutationResult(result);
      final entity = result.getOrElse(() => throw 'Expected Right').entity;
      expect(entity.title, 'New Assignment');

      final row = await _getAssignmentRow(entity.id);
      expect(row, isNotNull);
      expect(row![AssignmentsCols.title], 'New Assignment');
      expect(row[CommonCols.syncStatus], SyncStatus.pending.dbValue);

      final queue = await _getSyncQueueRows();
      _assertSyncQueueEntry(queue, count: 1, entityType: SyncEntityType.assignment, operation: SyncOperation.create);
      final payload = _decodePayload(queue.first);
      expect(payload['id'], entity.id);
      expect(payload['class_id'], 'class-1');
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // Segment 1: Assignment Entity Writes
  // ═══════════════════════════════════════════════════════════════════════════
  group('updateAssignment', () {
    test('returns MutationResult<Assignment> with pending and enqueues update op', () async {
      await _seedAssignment(local, _fakeAssignment(id: 'a1', title: 'Old Title'));

      final result = await updateAssignment(
        local,
        syncQueue,
        assignmentId: 'a1',
        title: 'New Title',
      );

      _assertMutationResult(result);
      final entity = result.getOrElse(() => throw 'Expected Right').entity;
      expect(entity.title, 'New Title');

      final row = await _getAssignmentRow('a1');
      expect(row![AssignmentsCols.title], 'New Title');
      expect(row[CommonCols.syncStatus], SyncStatus.pending.dbValue);

      final queue = await _getSyncQueueRows();
      _assertSyncQueueEntry(queue, count: 1, entityType: SyncEntityType.assignment, operation: SyncOperation.update);
      final payload = _decodePayload(queue.first);
      expect(payload['id'], 'a1');
      expect(payload['title'], 'New Title');
    });
  });

  group('deleteAssignment', () {
    test('returns MutationResult<void> with pending, soft-deletes and enqueues delete op', () async {
      await _seedAssignment(local, _fakeAssignment(id: 'a1'));

      final result = await deleteAssignment(
        local,
        syncQueue,
        assignmentId: 'a1',
      );

      _assertMutationResult(result);

      final row = await _getAssignmentRow('a1');
      expect(row![CommonCols.deletedAt], isNotNull);

      final queue = await _getSyncQueueRows();
      _assertSyncQueueEntry(queue, count: 1, entityType: SyncEntityType.assignment, operation: SyncOperation.delete);
      final payload = _decodePayload(queue.first);
      expect(payload['id'], 'a1');
    });
  });

  group('publishAssignment', () {
    test('returns MutationResult<Assignment> with pending and enqueues publish op', () async {
      await _seedAssignment(local, _fakeAssignment(id: 'a1', isPublished: false));

      final result = await publishAssignment(
        local,
        syncQueue,
        assignmentId: 'a1',
      );

      _assertMutationResult(result);
      final entity = result.getOrElse(() => throw 'Expected Right').entity;
      expect(entity.isPublished, isTrue);

      final row = await _getAssignmentRow('a1');
      expect(row![AssignmentsCols.isPublished], 1);
      expect(row[CommonCols.syncStatus], SyncStatus.pending.dbValue);

      final queue = await _getSyncQueueRows();
      _assertSyncQueueEntry(queue, count: 1, entityType: SyncEntityType.assignment, operation: SyncOperation.update);
      final payload = _decodePayload(queue.first);
      expect(payload['id'], 'a1');
    });
  });

  group('unpublishAssignment', () {
    test('returns MutationResult<Assignment> with pending and enqueues unpublish op', () async {
      await _seedAssignment(local, _fakeAssignment(id: 'a1', isPublished: true));

      final result = await unpublishAssignment(
        local,
        syncQueue,
        assignmentId: 'a1',
      );

      _assertMutationResult(result);
      final entity = result.getOrElse(() => throw 'Expected Right').entity;
      expect(entity.isPublished, isFalse);

      final row = await _getAssignmentRow('a1');
      expect(row![AssignmentsCols.isPublished], 0);
      expect(row[CommonCols.syncStatus], SyncStatus.pending.dbValue);

      final queue = await _getSyncQueueRows();
      _assertSyncQueueEntry(queue, count: 1, entityType: SyncEntityType.assignment, operation: SyncOperation.unpublish);
      final payload = _decodePayload(queue.first);
      expect(payload['id'], 'a1');
    });
  });

  group('reorderAllAssignments', () {
    test('returns MutationResult<void> with pending, updates order and enqueues single op', () async {
      await _seedAssignment(local, _fakeAssignment(id: 'a1', orderIndex: 0));
      await _seedAssignment(local, _fakeAssignment(id: 'a2', orderIndex: 1));

      final result = await reorderAllAssignments(
        local,
        syncQueue,
        classId: 'class-1',
        assignmentIds: ['a2', 'a1'],
      );

      _assertMutationResult(result);

      final rowA1 = await _getAssignmentRow('a1');
      final rowA2 = await _getAssignmentRow('a2');
      expect(rowA1![AssignmentsCols.orderIndex], 1);
      expect(rowA2![AssignmentsCols.orderIndex], 0);
      expect(rowA1[CommonCols.syncStatus], SyncStatus.pending.dbValue);
      expect(rowA2[CommonCols.syncStatus], SyncStatus.pending.dbValue);

      final queue = await _getSyncQueueRows();
      _assertSyncQueueEntry(queue, count: 1, entityType: SyncEntityType.assignment, operation: SyncOperation.update);
      final payload = _decodePayload(queue.first);
      expect(payload.containsKey('class_id'), isTrue);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // Segment 2: Submission Lifecycle Writes
  // ═══════════════════════════════════════════════════════════════════════════
  group('createSubmission', () {
    test('returns MutationResult<AssignmentSubmission> with pending and enqueues create op', () async {
      await _seedAssignment(local, _fakeAssignment(id: 'a1'));

      final mockStorage = MockStorageService();
      when(() => mockStorage.getUserId()).thenAnswer((_) async => 'student-1');

      final result = await createSubmission(
        local,
        syncQueue,
        mockStorage,
        assignmentId: 'a1',
        textContent: 'My answer',
      );

      _assertMutationResult(result);
      final entity = result.getOrElse(() => throw 'Expected Right').entity;
      expect(entity.assignmentId, 'a1');
      expect(entity.textContent, 'My answer');
      expect(entity.status, 'draft');

      final row = await _getSubmissionRow(entity.id);
      expect(row, isNotNull);
      expect(row![AssignmentSubmissionsCols.textContent], 'My answer');
      expect(row[CommonCols.syncStatus], SyncStatus.pending.dbValue);

      final queue = await _getSyncQueueRows();
      _assertSyncQueueEntry(
        queue,
        count: 1,
        entityType: SyncEntityType.assignmentSubmission,
        operation: SyncOperation.create,
      );
      final payload = _decodePayload(queue.first);
      expect(payload['id'], entity.id);
      expect(payload['assignment_id'], 'a1');
    });
  });

  group('submitAssignment', () {
    test('returns MutationResult<AssignmentSubmission> with pending and enqueues submit op', () async {
      await _seedAssignment(local, _fakeAssignment(id: 'a1'));
      await _seedSubmission(local, _fakeSubmission(id: 's1', assignmentId: 'a1', status: 'draft'));

      final result = await submitAssignment(
        local,
        syncQueue,
        submissionId: 's1',
      );

      _assertMutationResult(result);
      final entity = result.getOrElse(() => throw 'Expected Right').entity;
      expect(entity.status, 'submitted');

      final row = await _getSubmissionRow('s1');
      expect(row![AssignmentSubmissionsCols.status], 'submitted');
      expect(row[CommonCols.syncStatus], SyncStatus.pending.dbValue);

      final queue = await _getSyncQueueRows();
      _assertSyncQueueEntry(
        queue,
        count: 1,
        entityType: SyncEntityType.assignmentSubmission,
        operation: SyncOperation.submit,
      );
      final payload = _decodePayload(queue.first);
      expect(payload['submission_id'], 's1');
    });
  });

  group('gradeSubmission', () {
    test('returns MutationResult<AssignmentSubmission> with pending and enqueues grade op', () async {
      await _seedAssignment(local, _fakeAssignment(id: 'a1'));
      await _seedSubmission(local, _fakeSubmission(id: 's1', assignmentId: 'a1', status: 'submitted'));

      final result = await gradeSubmission(
        local,
        syncQueue,
        submissionId: 's1',
        score: 85,
        feedback: 'Good work',
      );

      _assertMutationResult(result);
      final entity = result.getOrElse(() => throw 'Expected Right').entity;
      expect(entity.status, 'graded');
      expect(entity.score, 85);

      final row = await _getSubmissionRow('s1');
      expect(row![AssignmentSubmissionsCols.points], 85);
      expect(row[AssignmentSubmissionsCols.feedback], 'Good work');
      expect(row[CommonCols.syncStatus], SyncStatus.pending.dbValue);

      final queue = await _getSyncQueueRows();
      _assertSyncQueueEntry(
        queue,
        count: 1,
        entityType: SyncEntityType.assignmentSubmission,
        operation: SyncOperation.grade,
      );
      final payload = _decodePayload(queue.first);
      expect(payload['id'], 's1');
      expect(payload['score'], 85);
    });
  });

  group('returnSubmission', () {
    test('returns MutationResult<AssignmentSubmission> with pending and enqueues return op', () async {
      await _seedAssignment(local, _fakeAssignment(id: 'a1'));
      await _seedSubmission(local, _fakeSubmission(id: 's1', assignmentId: 'a1', status: 'graded'));

      final result = await returnSubmission(
        local,
        syncQueue,
        submissionId: 's1',
      );

      _assertMutationResult(result);
      final entity = result.getOrElse(() => throw 'Expected Right').entity;
      expect(entity.status, 'returned');

      final row = await _getSubmissionRow('s1');
      expect(row![AssignmentSubmissionsCols.status], 'returned');
      expect(row[CommonCols.syncStatus], SyncStatus.pending.dbValue);

      final queue = await _getSyncQueueRows();
      _assertSyncQueueEntry(
        queue,
        count: 1,
        entityType: SyncEntityType.assignmentSubmission,
        operation: SyncOperation.update,
      );
      final payload = _decodePayload(queue.first);
      expect(payload['id'], 's1');
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // Segment 3: File Operations
  // ═══════════════════════════════════════════════════════════════════════════
  group('uploadFile', () {
    test(
      'returns MutationResult<SubmissionFile> with pending and enqueues upload op',
      () async {
        final result = await uploadFile(
          local,
          syncQueue,
          submissionId: 's1',
          filePath: '/tmp/test.pdf',
          fileName: 'test.pdf',
        );

        _assertMutationResult(result);
        final entity = result.getOrElse(() => throw 'Expected Right').entity;
        expect(entity.fileName, 'test.pdf');

        final row = await _getFileRow(entity.id);
        expect(row, isNotNull);
        expect(row![SubmissionFilesCols.fileName], 'test.pdf');
        expect(row[CommonCols.syncStatus], SyncStatus.pending.dbValue);

        final queue = await _getSyncQueueRows();
        _assertSyncQueueEntry(
          queue,
          count: 1,
          entityType: SyncEntityType.submissionFile,
          operation: SyncOperation.upload,
        );
        final payload = _decodePayload(queue.first);
        expect(payload['file_id'], entity.id);
        expect(payload['submission_id'], 's1');
      },
      skip: 'Requires path_provider platform channel and file system setup in unit-test environment',
    );
  });

  group('deleteFile', () {
    test('returns MutationResult<void> with pending, deletes file and enqueues delete op', () async {
      await _seedFile(local, 's1', _fakeFile(id: 'f1'));

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
        entityType: SyncEntityType.submissionFile,
        operation: SyncOperation.delete,
      );
      final payload = _decodePayload(queue.first);
      expect(payload['file_id'], 'f1');
    });
  });
}
