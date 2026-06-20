import 'package:flutter_test/flutter_test.dart';
import 'package:likha/core/database/db_schema.dart';
import 'package:likha/core/database/local_database.dart';
import 'package:likha/core/sync/sync_queue.dart';
import 'package:likha/data/datasources/local/assessments/assessment_local_datasource.dart';

import '../../helpers/test_database.dart';

const _classId = 'class-001';
const _studentId = 'student-001';

void main() {
  late AssessmentLocalDataSourceImpl datasource;
  late SyncQueueImpl syncQueue;

  setUp(() async {
    await openFreshTestDatabase();
    syncQueue = SyncQueueImpl(LocalDatabase());
    datasource = AssessmentLocalDataSourceImpl(LocalDatabase(), syncQueue);
  });

  tearDown(() => closeTestDatabase());

  group('AssessmentLocalDataSource', () {
    test('createAssessment inserts assessment with sync_status=pending', () async {
      final id = await datasource.createAssessment(
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
      expect(rows.first['sync_status'], 'pending');
    });

    test('cacheAssessments and getCachedAssessments returns list for class', () async {
      // Create first, then verify retrieval
      await datasource.createAssessment(
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

    test('startAssessment creates a submission in the DB', () async {
      final assessmentId = await datasource.createAssessment(
        classId: _classId,
        title: 'Quiz 2',
        timeLimitMinutes: 15,
        openAt: '2026-04-20T08:00:00',
        closeAt: '2026-04-20T09:00:00',
      );
      final submissionId = await datasource.startAssessment(
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
      final id = await datasource.createAssessment(
        classId: _classId,
        title: 'To Delete',
        timeLimitMinutes: 10,
        openAt: '2026-04-20T08:00:00',
        closeAt: '2026-04-20T09:00:00',
      );
      await datasource.deleteAssessment(assessmentId: id);
      final list = await datasource.getCachedAssessments(_classId);
      expect(list, isEmpty);
    });
  });
}
