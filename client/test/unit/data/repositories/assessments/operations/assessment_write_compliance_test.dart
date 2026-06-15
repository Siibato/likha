import 'dart:convert';

import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:likha/core/database/db_schema.dart';
import 'package:likha/core/database/local_database.dart';
import 'package:likha/core/errors/failures.dart';
import 'package:likha/core/sync/mutation_result.dart';
import 'package:likha/core/sync/sync_queue.dart';
import 'package:likha/data/datasources/local/assessments/assessment_local_datasource.dart';
import 'package:likha/data/models/assessments/assessment_model.dart';
import 'package:likha/data/models/assessments/question_model.dart';
import 'package:likha/data/models/assessments/submission_model.dart';
import 'package:likha/data/repositories/assessments/operations/add_questions.dart';
import 'package:likha/data/repositories/assessments/operations/create_assessment.dart';
import 'package:likha/data/repositories/assessments/operations/delete_assessment.dart';
import 'package:likha/data/repositories/assessments/operations/delete_question.dart';
import 'package:likha/data/repositories/assessments/operations/grade_essay_answer.dart';
import 'package:likha/data/repositories/assessments/operations/override_answer.dart';
import 'package:likha/data/repositories/assessments/operations/publish_assessment.dart';
import 'package:likha/data/repositories/assessments/operations/release_results.dart';
import 'package:likha/data/repositories/assessments/operations/reorder_all_assessments.dart';
import 'package:likha/data/repositories/assessments/operations/reorder_questions.dart';
import 'package:likha/data/repositories/assessments/operations/save_answers.dart';
import 'package:likha/data/repositories/assessments/operations/start_assessment.dart';
import 'package:likha/data/repositories/assessments/operations/submit_assessment.dart';
import 'package:likha/data/repositories/assessments/operations/unpublish_assessment.dart';
import 'package:likha/data/repositories/assessments/operations/update_assessment.dart';
import 'package:likha/data/repositories/assessments/operations/update_question.dart';

import '../../../../../helpers/mock_datasources.dart';
import '../../../../../helpers/test_database.dart';

// ─── Helpers ───────────────────────────────────────────────────────────────────

AssessmentModel _fakeAssessment({
  String id = 'assessment-1',
  String classId = 'class-1',
  String title = 'Test Assessment',
  bool isPublished = false,
  bool resultsReleased = false,
  int orderIndex = 0,
  int totalPoints = 100,
  int questionCount = 0,
}) {
  final now = DateTime.now();
  return AssessmentModel(
    id: id,
    classId: classId,
    title: title,
    description: 'Test description',
    timeLimitMinutes: 60,
    openAt: DateTime(2025, 1, 1),
    closeAt: DateTime(2025, 12, 31),
    showResultsImmediately: false,
    resultsReleased: resultsReleased,
    isPublished: isPublished,
    orderIndex: orderIndex,
    totalPoints: totalPoints,
    questionCount: questionCount,
    submissionCount: 0,
    createdAt: now,
    updatedAt: now,
    syncStatus: SyncStatus.synced,
  );
}

QuestionModel _fakeQuestion({
  String id = 'question-1',
  String assessmentId = 'assessment-1',
  String questionType = 'multiple_choice',
  String questionText = 'What is 2+2?',
  int points = 1,
  int orderIndex = 0,
}) {
  return QuestionModel(
    id: id,
    assessmentId: assessmentId,
    questionType: questionType,
    questionText: questionText,
    points: points,
    orderIndex: orderIndex,
    isMultiSelect: false,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
    syncStatus: SyncStatus.synced,
  );
}

SubmissionSummaryModel _fakeSubmission({
  String id = 'submission-1',
  String assessmentId = 'assessment-1',
  String studentId = 'student-1',
}) {
  final now = DateTime.now();
  return SubmissionSummaryModel(
    id: id,
    assessmentId: assessmentId,
    studentId: studentId,
    studentName: 'Test Student',
    studentUsername: 'teststudent',
    startedAt: now,
    autoScore: 0.0,
    finalScore: 0.0,
    totalPoints: 100.0,
    isSubmitted: false,
    createdAt: now,
    updatedAt: now,
    syncStatus: SyncStatus.synced,
  );
}

Future<void> _seedAssessment(AssessmentLocalDataSource local, AssessmentModel a) async {
  await local.cacheAssessments([a]);
}

Future<void> _seedQuestion(AssessmentLocalDataSource local, QuestionModel q) async {
  await local.cacheQuestions(q.assessmentId, [q]);
}

Future<void> _seedSubmission(AssessmentLocalDataSource local, SubmissionSummaryModel s) async {
  await local.cacheStudentSubmission(s.assessmentId, s.studentId, s);
}

Future<List<Map<String, dynamic>>> _getSyncQueueRows() async {
  final db = await LocalDatabase().database;
  return db.query(DbTables.syncQueue);
}

Future<Map<String, dynamic>?> _getAssessmentRow(String id) async {
  final db = await LocalDatabase().database;
  final rows = await db.query(
    DbTables.assessments,
    where: '${CommonCols.id} = ?',
    whereArgs: [id],
  );
  return rows.isEmpty ? null : rows.first;
}

Future<Map<String, dynamic>?> _getQuestionRow(String id) async {
  final db = await LocalDatabase().database;
  final rows = await db.query(
    DbTables.assessmentQuestions,
    where: '${CommonCols.id} = ?',
    whereArgs: [id],
  );
  return rows.isEmpty ? null : rows.first;
}

Future<Map<String, dynamic>?> _getSubmissionRow(String id) async {
  final db = await LocalDatabase().database;
  final rows = await db.query(
    DbTables.assessmentSubmissions,
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
  late AssessmentLocalDataSourceImpl local;
  late SyncQueueImpl syncQueue;
  late MockAssessmentRemoteDataSource remote;

  setUp(() async {
    await openFreshTestDatabase();
    syncQueue = SyncQueueImpl(LocalDatabase());
    local = AssessmentLocalDataSourceImpl(LocalDatabase(), syncQueue);
    remote = MockAssessmentRemoteDataSource();
  });

  tearDown(() async {
    await closeTestDatabase();
  });

  group('createAssessment', () {
    test('returns MutationResult<Assessment> with pending and enqueues create op', () async {
      final result = await createAssessment(
        local,
        syncQueue,
        remote,
        classId: 'class-1',
        title: 'New Assessment',
        description: 'A test assessment',
        timeLimitMinutes: 60,
        openAt: '2025-06-01T08:00:00',
        closeAt: '2025-06-01T09:00:00',
        isPublished: false,
      );

      _assertMutationResult(result);
      final entity = result.getOrElse(() => throw 'Expected Right').entity;
      expect(entity.title, 'New Assessment');

      final row = await _getAssessmentRow(entity.id);
      expect(row, isNotNull);
      expect(row![AssessmentsCols.title], 'New Assessment');
      expect(row[CommonCols.syncStatus], SyncStatus.pending.dbValue);

      final queue = await _getSyncQueueRows();
      _assertSyncQueueEntry(queue, count: 1, entityType: SyncEntityType.assessment, operation: SyncOperation.create);
      final payload = _decodePayload(queue.first);
      expect(payload['id'], entity.id);
      expect(payload['class_id'], 'class-1');
    });
  });

  group('updateAssessment', () {
    test('returns MutationResult<Assessment> with pending and enqueues update op', () async {
      await _seedAssessment(local, _fakeAssessment(id: 'a1', title: 'Old Title'));

      final result = await updateAssessment(
        local,
        syncQueue,
        remote,
        assessmentId: 'a1',
        title: 'New Title',
      );

      _assertMutationResult(result);
      final entity = result.getOrElse(() => throw 'Expected Right').entity;
      expect(entity.title, 'New Title');

      final row = await _getAssessmentRow('a1');
      expect(row![AssessmentsCols.title], 'New Title');
      expect(row[CommonCols.syncStatus], SyncStatus.pending.dbValue);

      final queue = await _getSyncQueueRows();
      _assertSyncQueueEntry(queue, count: 1, entityType: SyncEntityType.assessment, operation: SyncOperation.update);
      final payload = _decodePayload(queue.first);
      expect(payload['id'], 'a1');
      expect(payload['title'], 'New Title');
    });
  });

  group('deleteAssessment', () {
    test('returns MutationResult<void> with pending, soft-deletes and enqueues delete op', () async {
      await _seedAssessment(local, _fakeAssessment(id: 'a1'));

      final result = await deleteAssessment(
        local,
        syncQueue,
        remote,
        assessmentId: 'a1',
      );

      _assertMutationResult(result);

      final row = await _getAssessmentRow('a1');
      expect(row![CommonCols.deletedAt], isNotNull);

      final queue = await _getSyncQueueRows();
      _assertSyncQueueEntry(queue, count: 1, entityType: SyncEntityType.assessment, operation: SyncOperation.delete);
      final payload = _decodePayload(queue.first);
      expect(payload['id'], 'a1');
    });
  });

  group('publishAssessment', () {
    test('returns MutationResult<Assessment> with pending and enqueues publish op', () async {
      await _seedAssessment(local, _fakeAssessment(id: 'a1', isPublished: false));
      await _seedQuestion(local, _fakeQuestion(id: 'q1', assessmentId: 'a1'));

      final result = await publishAssessment(
        local,
        syncQueue,
        remote,
        assessmentId: 'a1',
      );

      _assertMutationResult(result);
      final entity = result.getOrElse(() => throw 'Expected Right').entity;
      expect(entity.isPublished, isTrue);

      final row = await _getAssessmentRow('a1');
      expect(row![AssessmentsCols.isPublished], 1);
      expect(row[CommonCols.syncStatus], SyncStatus.pending.dbValue);

      final queue = await _getSyncQueueRows();
      _assertSyncQueueEntry(queue, count: 1, entityType: SyncEntityType.assessment, operation: SyncOperation.publish);
      final payload = _decodePayload(queue.first);
      expect(payload['id'], 'a1');
    });
  });

  group('unpublishAssessment', () {
    test('returns MutationResult<Assessment> with pending and enqueues unpublish op', () async {
      await _seedAssessment(local, _fakeAssessment(id: 'a1', isPublished: true));

      final result = await unpublishAssessment(
        local,
        syncQueue,
        remote,
        assessmentId: 'a1',
      );

      _assertMutationResult(result);
      final entity = result.getOrElse(() => throw 'Expected Right').entity;
      expect(entity.isPublished, isFalse);

      final row = await _getAssessmentRow('a1');
      expect(row![AssessmentsCols.isPublished], 0);
      expect(row[CommonCols.syncStatus], SyncStatus.pending.dbValue);

      final queue = await _getSyncQueueRows();
      _assertSyncQueueEntry(queue, count: 1, entityType: SyncEntityType.assessment, operation: SyncOperation.unpublish);
      final payload = _decodePayload(queue.first);
      expect(payload['id'], 'a1');
    });
  });

  group('reorderAllAssessments', () {
    test('returns MutationResult<void> with pending, updates order and enqueues single op', () async {
      await _seedAssessment(local, _fakeAssessment(id: 'a1', orderIndex: 0));
      await _seedAssessment(local, _fakeAssessment(id: 'a2', orderIndex: 1));

      final result = await reorderAllAssessments(
        local,
        syncQueue,
        remote,
        classId: 'class-1',
        assessmentIds: ['a2', 'a1'],
      );

      _assertMutationResult(result);

      final rowA1 = await _getAssessmentRow('a1');
      final rowA2 = await _getAssessmentRow('a2');
      expect(rowA1![AssessmentsCols.orderIndex], 1);
      expect(rowA2![AssessmentsCols.orderIndex], 0);
      expect(rowA1[CommonCols.syncStatus], SyncStatus.pending.dbValue);
      expect(rowA2[CommonCols.syncStatus], SyncStatus.pending.dbValue);

      final queue = await _getSyncQueueRows();
      _assertSyncQueueEntry(queue, count: 1, entityType: SyncEntityType.assessment, operation: SyncOperation.reorder);
      final payload = _decodePayload(queue.first);
      expect(payload.containsKey('class_id'), isTrue);
      expect(payload['assessment_ids'], ['a2', 'a1']);
    });
  });

  group('addQuestions', () {
    test('returns MutationResult<List<Question>> with pending and enqueues create op', () async {
      await _seedAssessment(local, _fakeAssessment(id: 'a1'));

      final result = await addQuestions(
        local,
        syncQueue,
        remote,
        assessmentId: 'a1',
        questions: [
          {
            'question_type': 'multiple_choice',
            'question_text': 'Q1',
            'points': 1,
            'order_index': 0,
          },
          {
            'question_type': 'essay',
            'question_text': 'Q2',
            'points': 5,
            'order_index': 1,
          },
        ],
      );

      _assertMutationResult(result);
      final entities = result.getOrElse(() => throw 'Expected Right').entity;
      expect(entities.length, 2);

      final queue = await _getSyncQueueRows();
      _assertSyncQueueEntry(queue, count: 1, entityType: SyncEntityType.question, operation: SyncOperation.create);
      final payload = _decodePayload(queue.first);
      expect(payload['assessment_id'], 'a1');
    });
  });

  group('updateQuestion', () {
    test('returns MutationResult<Question> with pending and enqueues update op', () async {
      await _seedAssessment(local, _fakeAssessment(id: 'a1'));
      await _seedQuestion(local, _fakeQuestion(id: 'q1', assessmentId: 'a1', questionText: 'Old Q'));

      final result = await updateQuestion(
        local,
        syncQueue,
        remote,
        questionId: 'q1',
        data: {'question_text': 'New Q', 'points': 2},
      );

      _assertMutationResult(result);
      final entity = result.getOrElse(() => throw 'Expected Right').entity;
      expect(entity.questionText, 'New Q');

      final row = await _getQuestionRow('q1');
      expect(row![AssessmentQuestionsCols.questionText], 'New Q');
      expect(row[AssessmentQuestionsCols.points], 2);
      expect(row[CommonCols.syncStatus], SyncStatus.pending.dbValue);

      final queue = await _getSyncQueueRows();
      _assertSyncQueueEntry(queue, count: 1, entityType: SyncEntityType.question, operation: SyncOperation.update);
      final payload = _decodePayload(queue.first);
      expect(payload['id'], 'q1');
    });
  });

  group('deleteQuestion', () {
    test('returns MutationResult<void> with pending, soft-deletes and enqueues delete op', () async {
      await _seedAssessment(local, _fakeAssessment(id: 'a1'));
      await _seedQuestion(local, _fakeQuestion(id: 'q1', assessmentId: 'a1'));

      final result = await deleteQuestion(
        local,
        syncQueue,
        remote,
        questionId: 'q1',
      );

      _assertMutationResult(result);

      final row = await _getQuestionRow('q1');
      expect(row![CommonCols.deletedAt], isNotNull);

      final queue = await _getSyncQueueRows();
      _assertSyncQueueEntry(queue, count: 1, entityType: SyncEntityType.question, operation: SyncOperation.delete);
      final payload = _decodePayload(queue.first);
      expect(payload['id'], 'q1');
    });
  });

  group('reorderQuestions', () {
    test('returns MutationResult<void> with pending, updates order and enqueues single op', () async {
      await _seedAssessment(local, _fakeAssessment(id: 'a1'));
      await _seedQuestion(local, _fakeQuestion(id: 'q1', assessmentId: 'a1', orderIndex: 0));
      await _seedQuestion(local, _fakeQuestion(id: 'q2', assessmentId: 'a1', orderIndex: 1));

      final result = await reorderQuestions(
        local,
        syncQueue,
        remote,
        assessmentId: 'a1',
        questionIds: ['q2', 'q1'],
      );

      _assertMutationResult(result);

      final rowQ1 = await _getQuestionRow('q1');
      final rowQ2 = await _getQuestionRow('q2');
      expect(rowQ1![AssessmentQuestionsCols.orderIndex], 1);
      expect(rowQ2![AssessmentQuestionsCols.orderIndex], 0);
      expect(rowQ1[CommonCols.syncStatus], SyncStatus.pending.dbValue);
      expect(rowQ2[CommonCols.syncStatus], SyncStatus.pending.dbValue);

      final queue = await _getSyncQueueRows();
      _assertSyncQueueEntry(queue, count: 1, entityType: SyncEntityType.question, operation: SyncOperation.reorder);
      final payload = _decodePayload(queue.first);
      expect(payload.containsKey('assessment_id'), isTrue);
    });
  });

  group('startAssessment', () {
    test('returns MutationResult<StartSubmissionResult> with pending and enqueues create op', () async {
      await _seedAssessment(local, _fakeAssessment(id: 'a1'));
      await _seedQuestion(local, _fakeQuestion(id: 'q1', assessmentId: 'a1'));

      final result = await startAssessment(
        local,
        syncQueue,
        remote,
        assessmentId: 'a1',
        studentId: 'student-1',
        studentName: 'Test Student',
        studentUsername: 'teststudent',
      );

      _assertMutationResult(result);
      final entity = result.getOrElse(() => throw 'Expected Right').entity;
      expect(entity.submissionId, isNotEmpty);

      final row = await _getSubmissionRow(entity.submissionId);
      expect(row, isNotNull);
      expect(row![CommonCols.syncStatus], SyncStatus.pending.dbValue);

      final queue = await _getSyncQueueRows();
      _assertSyncQueueEntry(
        queue,
        count: 1,
        entityType: SyncEntityType.assessmentSubmission,
        operation: SyncOperation.create,
      );
      final payload = _decodePayload(queue.first);
      expect(payload['id'], entity.submissionId);
    });
  });

  group('submitAssessment', () {
    test('returns MutationResult<SubmissionSummary> with pending and enqueues submit op', () async {
      await _seedAssessment(local, _fakeAssessment(id: 'a1'));
      await _seedSubmission(local, _fakeSubmission(id: 's1', assessmentId: 'a1'));

      final result = await submitAssessment(
        local,
        syncQueue,
        remote,
        submissionId: 's1',
      );

      _assertMutationResult(result);
      final entity = result.getOrElse(() => throw 'Expected Right').entity;
      expect(entity.isSubmitted, isTrue);

      final row = await _getSubmissionRow('s1');
      expect(row![AssessmentSubmissionsCols.submittedAt], isNotNull);
      expect(row[CommonCols.syncStatus], SyncStatus.pending.dbValue);

      final queue = await _getSyncQueueRows();
      _assertSyncQueueEntry(
        queue,
        count: 1,
        entityType: SyncEntityType.assessmentSubmission,
        operation: SyncOperation.submit,
      );
      final payload = _decodePayload(queue.first);
      expect(payload['submission_id'], 's1');
    });
  });

  group('saveAnswers', () {
    test('returns MutationResult<void> with pending and enqueues save_answers op', () async {
      await _seedAssessment(local, _fakeAssessment(id: 'a1'));
      await _seedSubmission(local, _fakeSubmission(id: 's1', assessmentId: 'a1'));

      final result = await saveAnswers(
        local,
        syncQueue,
        remote,
        submissionId: 's1',
        answers: [
          {
            'question_id': 'q1',
            'answer_text': 'My answer',
          },
        ],
      );

      _assertMutationResult(result);

      final queue = await _getSyncQueueRows();
      _assertSyncQueueEntry(
        queue,
        count: 1,
        entityType: SyncEntityType.assessmentSubmission,
        operation: SyncOperation.saveAnswers,
      );
      final payload = _decodePayload(queue.first);
      expect(payload['submission_id'], 's1');
    });
  });

  group('releaseResults', () {
    test('returns MutationResult<Assessment> with pending and enqueues release_results op', () async {
      await _seedAssessment(local, _fakeAssessment(id: 'a1', resultsReleased: false));

      final result = await releaseResults(
        local,
        syncQueue,
        remote,
        assessmentId: 'a1',
      );

      _assertMutationResult(result);
      final entity = result.getOrElse(() => throw 'Expected Right').entity;
      expect(entity.resultsReleased, isTrue);

      final row = await _getAssessmentRow('a1');
      expect(row![AssessmentsCols.resultsReleased], 1);
      expect(row[CommonCols.syncStatus], SyncStatus.pending.dbValue);

      final queue = await _getSyncQueueRows();
      _assertSyncQueueEntry(
        queue,
        count: 1,
        entityType: SyncEntityType.assessment,
        operation: SyncOperation.releaseResults,
      );
      final payload = _decodePayload(queue.first);
      expect(payload['id'], 'a1');
    });
  });

  group('gradeEssayAnswer', () {
    test('returns MutationResult<void> with pending and enqueues grade_essay op', () async {
      await _seedAssessment(local, _fakeAssessment(id: 'a1'));
      await _seedSubmission(local, _fakeSubmission(id: 's1', assessmentId: 'a1'));
      final db = await LocalDatabase().database;
      await db.insert(DbTables.submissionAnswers, {
        CommonCols.id: 'ans-1',
        SubmissionAnswersCols.submissionId: 's1',
        SubmissionAnswersCols.questionId: 'q1',
        SubmissionAnswersCols.points: 5,
      });

      final result = await gradeEssayAnswer(
        local,
        syncQueue,
        remote,
        answerId: 'ans-1',
        points: 4.0,
      );

      _assertMutationResult(result);

      final queue = await _getSyncQueueRows();
      _assertSyncQueueEntry(
        queue,
        count: 1,
        entityType: SyncEntityType.assessmentSubmission,
        operation: SyncOperation.gradeEssay,
      );
      final payload = _decodePayload(queue.first);
      expect(payload['answer_id'], 'ans-1');
      expect(payload['points'], 4.0);
    });
  });

  group('overrideAnswer', () {
    test('returns MutationResult<void> with pending and enqueues override_answer op', () async {
      await _seedAssessment(local, _fakeAssessment(id: 'a1'));
      await _seedSubmission(local, _fakeSubmission(id: 's1', assessmentId: 'a1'));
      final db = await LocalDatabase().database;
      await db.insert(DbTables.submissionAnswers, {
        CommonCols.id: 'ans-1',
        SubmissionAnswersCols.submissionId: 's1',
        SubmissionAnswersCols.questionId: 'q1',
        SubmissionAnswersCols.points: 5,
      });

      final result = await overrideAnswer(
        local,
        syncQueue,
        remote,
        answerId: 'ans-1',
        isCorrect: true,
        points: 5.0,
      );

      _assertMutationResult(result);

      final queue = await _getSyncQueueRows();
      _assertSyncQueueEntry(
        queue,
        count: 1,
        entityType: SyncEntityType.assessmentSubmission,
        operation: SyncOperation.overrideAnswer,
      );
      final payload = _decodePayload(queue.first);
      expect(payload['answer_id'], 'ans-1');
      expect(payload['is_correct'], isTrue);
    });
  });
}
