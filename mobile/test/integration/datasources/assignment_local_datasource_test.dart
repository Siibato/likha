import 'package:flutter_test/flutter_test.dart';
import 'package:likha/core/database/db_schema.dart';
import 'package:likha/core/database/local_database.dart';
import 'package:likha/core/security/noop_encryption_service.dart';
import 'package:likha/core/sync/sync_queue.dart';
import 'package:likha/data/datasources/local/assignments/impl/assignment_local_datasource_impl.dart';
import 'package:likha/data/models/assignments/assignment_model.dart';

import '../../helpers/test_database.dart';

const _classId = 'class-001';
const _studentId = 'student-001';

AssignmentModel _sampleAssignment({String id = 'assignment-001', bool isPublished = true, String? deletedAt}) {
  return AssignmentModel(
    id: id,
    classId: _classId,
    title: 'Test Assignment',
    instructions: 'Do the task',
    totalPoints: 100,
    dueAt: DateTime(2026, 5, 1),
    isPublished: isPublished,
    orderIndex: 0,
    submissionCount: 0,
    gradedCount: 0,
    createdAt: DateTime(2026, 4, 19),
    updatedAt: DateTime(2026, 4, 19),
    deletedAt: deletedAt != null ? DateTime.parse(deletedAt) : null,
  );
}

void main() {
  late AssignmentLocalDataSourceImpl datasource;
  late SyncQueueImpl syncQueue;

  setUp(() async {
    await openFreshTestDatabase();
    syncQueue = SyncQueueImpl(LocalDatabase());
    datasource = AssignmentLocalDataSourceImpl(LocalDatabase(), syncQueue, const NoOpEncryptionService());
  });

  tearDown(() => closeTestDatabase());

  group('AssignmentLocalDataSource', () {
    test('cacheAssignments and getCachedAssignments returns cached list', () async {
      await datasource.cacheAssignments([_sampleAssignment()]);
      final result = await datasource.getCachedAssignments(_classId);
      expect(result.length, 1);
      expect(result.first.id, 'assignment-001');
      expect(result.first.title, 'Test Assignment');
    });

    test('getCachedAssignments excludes soft-deleted assignments', () async {
      await datasource.cacheAssignments([
        _sampleAssignment(id: 'a1'),
        _sampleAssignment(id: 'a2', deletedAt: '2026-04-19T08:00:00.000'),
      ]);
      final result = await datasource.getCachedAssignments(_classId);
      expect(result.length, 1);
      expect(result.first.id, 'a1');
    });

    test('getCachedAssignments with publishedOnly filters unpublished', () async {
      await datasource.cacheAssignments([
        _sampleAssignment(id: 'a1', isPublished: true),
        _sampleAssignment(id: 'a2', isPublished: false),
      ]);
      final result = await datasource.getCachedAssignments(_classId, publishedOnly: true);
      expect(result.length, 1);
      expect(result.first.id, 'a1');
    });

    test('createSubmissionLocally inserts a draft submission', () async {
      await datasource.cacheAssignments([_sampleAssignment()]);
      final submissionId = await datasource.createSubmissionLocally(
        assignmentId: 'assignment-001',
        studentId: _studentId,
        textContent: 'My answer',
      );
      expect(submissionId, isNotEmpty);

      final db = await LocalDatabase().database;
      final rows = await db.query(
        DbTables.assignmentSubmissions,
        where: 'id = ?',
        whereArgs: [submissionId],
      );
      expect(rows.length, 1);
      expect(rows.first['status'], 'draft');
      expect(rows.first['text_content'], 'My answer');
      expect(rows.first['needs_sync'], 1);
    });

    test('gradeSubmissionLocally updates score and feedback', () async {
      await datasource.cacheAssignments([_sampleAssignment()]);
      final submissionId = await datasource.createSubmissionLocally(
        assignmentId: 'assignment-001',
        studentId: _studentId,
      );
      await datasource.gradeSubmissionLocally(
        submissionId: submissionId,
        score: 85,
        feedback: 'Good work',
      );
      final db = await LocalDatabase().database;
      final rows = await db.query(
        DbTables.assignmentSubmissions,
        where: 'id = ?',
        whereArgs: [submissionId],
      );
      expect(rows.first['points'], 85);
      expect(rows.first['feedback'], 'Good work');
    });

    test('getCachedAssignments returns empty list for unknown class', () async {
      final result = await datasource.getCachedAssignments('no-such-class');
      expect(result, isEmpty);
    });
  });
}
