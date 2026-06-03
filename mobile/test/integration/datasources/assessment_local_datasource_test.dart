import 'package:flutter_test/flutter_test.dart';
import 'package:likha/core/database/db_schema.dart';
import 'package:likha/core/database/local_database.dart';
import 'package:likha/core/security/noop_encryption_service.dart';
import 'package:likha/core/sync/sync_queue.dart';
import 'package:likha/data/datasources/local/assessments/impl/assessment_local_datasource_impl.dart';

import '../../helpers/test_database.dart';

const _classId = 'class-001';
const _studentId = 'student-001';

void main() {
  late AssessmentLocalDataSourceImpl datasource;
  late SyncQueueImpl syncQueue;

  setUp(() async {
    await openFreshTestDatabase();
    syncQueue = SyncQueueImpl(LocalDatabase());
    datasource = AssessmentLocalDataSourceImpl(LocalDatabase(), syncQueue, const NoOpEncryptionService());
  });

  tearDown(() => closeTestDatabase());

  group('AssessmentLocalDataSource', () {
    test('createAssessmentLocally inserts assessment with needsSync=1', () async {
      final id = await datasource.createAssessmentLocally(
        classId: _classId,
        title: 'Quiz 1',
        timeLimitMinutes: 30,
        openAt: '2026-04-20T08:00:00',
        closeAt: '2026-04-20T09:00:00',
        isPublished: true,
      );
      expect(id, isNotEmpty);

      final db = await LocalDatabase().database;
      final rows = await db.query(
        DbTables.assessments,
        where: '${CommonCols.id} = ?',
        whereArgs: [id],
      );
      expect(rows.length, 1);
      expect(rows.first['title'], 'Quiz 1');
      expect(rows.first['needs_sync'], 1);
    });

    test('cacheAssessments and getCachedAssessments returns list for class', () async {
      // Create first, then verify retrieval
      await datasource.createAssessmentLocally(
        classId: _classId,
        title: 'Assessment A',
        timeLimitMinutes: 60,
        openAt: '2026-04-20T08:00:00',
        closeAt: '2026-04-20T10:00:00',
      );
      final list = await datasource.getCachedAssessments(_classId);
      expect(list.length, 1);
      expect(list.first.title, 'Assessment A');
    });

    test('getCachedAssessments returns empty list for unknown class', () async {
      final list = await datasource.getCachedAssessments('no-such-class');
      expect(list, isEmpty);
    });

    test('startAssessmentLocally creates a submission in the DB', () async {
      final assessmentId = await datasource.createAssessmentLocally(
        classId: _classId,
        title: 'Quiz 2',
        timeLimitMinutes: 15,
        openAt: '2026-04-20T08:00:00',
        closeAt: '2026-04-20T09:00:00',
      );
      final submissionId = await datasource.startAssessmentLocally(
        assessmentId: assessmentId,
        studentId: _studentId,
        studentName: 'Alice',
        studentUsername: 'alice01',
      );
      expect(submissionId, isNotEmpty);

      final db = await LocalDatabase().database;
      final rows = await db.query(
        DbTables.assessmentSubmissions,
        where: '${CommonCols.id} = ?',
        whereArgs: [submissionId],
      );
      expect(rows.length, 1);
      expect(rows.first['assessment_id'], assessmentId);
      expect(rows.first['user_id'], _studentId);
    });

    test('getCachedAssessments excludes soft-deleted assessments', () async {
      final id = await datasource.createAssessmentLocally(
        classId: _classId,
        title: 'To Delete',
        timeLimitMinutes: 10,
        openAt: '2026-04-20T08:00:00',
        closeAt: '2026-04-20T09:00:00',
      );
      await datasource.deleteAssessmentLocally(assessmentId: id);
      final list = await datasource.getCachedAssessments(_classId);
      expect(list, isEmpty);
    });
  });
}
