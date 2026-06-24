import 'package:dartz/dartz.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:likha/core/errors/failures.dart';
import 'package:likha/core/sync/mutation_result.dart';
import 'package:likha/core/sync/sync_queue.dart';
import 'package:likha/domain/assignments/usecases/create_submission.dart';
import 'package:likha/domain/assignments/usecases/delete_file.dart';
import 'package:likha/domain/assignments/usecases/download_file.dart';
import 'package:likha/domain/assignments/usecases/get_submission_detail.dart';
import 'package:likha/domain/assignments/usecases/get_submissions.dart';
import 'package:likha/domain/assignments/usecases/grade_submission.dart';
import 'package:likha/domain/assignments/usecases/return_submission.dart';
import 'package:likha/domain/assignments/usecases/submit_assignment.dart';
import 'package:likha/presentation/providers/assignment/submission_provider.dart';

import '../../../../helpers/fake_entities.dart';

class _FakeRef implements Ref {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockGetSubmissions extends Mock implements GetAssignmentSubmissions {}
class MockGetSubmissionDetail extends Mock implements GetAssignmentSubmissionDetail {}
class MockGradeSubmission extends Mock implements GradeSubmission {}
class MockReturnSubmission extends Mock implements ReturnSubmission {}
class MockCreateSubmission extends Mock implements CreateSubmission {}
class MockDeleteFile extends Mock implements DeleteFile {}
class MockSubmitAssignment extends Mock implements SubmitAssignment {}
class MockDownloadFile extends Mock implements DownloadFile {}

SubmissionNotifier _buildNotifier({
  MockGetSubmissions? getSubmissions,
  MockGetSubmissionDetail? getSubmissionDetail,
  MockGradeSubmission? gradeSubmission,
  MockReturnSubmission? returnSubmission,
  MockCreateSubmission? createSubmission,
  MockDeleteFile? deleteFile,
  MockSubmitAssignment? submitAssignment,
  MockDownloadFile? downloadFile,
}) {
  return SubmissionNotifier(
    _FakeRef(),
    getSubmissions ?? MockGetSubmissions(),
    getSubmissionDetail ?? MockGetSubmissionDetail(),
    gradeSubmission ?? MockGradeSubmission(),
    returnSubmission ?? MockReturnSubmission(),
    createSubmission ?? MockCreateSubmission(),
    deleteFile ?? MockDeleteFile(),
    submitAssignment ?? MockSubmitAssignment(),
    downloadFile ?? MockDownloadFile(),
  );
}

void main() {
  final tSubmission = FakeEntities.assignmentSubmission();
  final tSubmissionListItem = FakeEntities.submissionListItem();

  group('SubmissionNotifier', () {
    group('loadSubmissions', () {
      test('populates submissions on success', () async {
        final mockGet = MockGetSubmissions();
        final notifier = _buildNotifier(getSubmissions: mockGet);

        when(() => mockGet(any()))
            .thenAnswer((_) async => Right([tSubmissionListItem]));

        await notifier.loadSubmissions('a-1');

        expect(notifier.state.isLoading, isFalse);
        expect(notifier.state.submissions.length, 1);
        expect(notifier.state.error, isNull);
      });

      test('sets error on failure', () async {
        final mockGet = MockGetSubmissions();
        final notifier = _buildNotifier(getSubmissions: mockGet);

        when(() => mockGet(any()))
            .thenAnswer((_) async => const Left(ServerFailure('Network error')));

        await notifier.loadSubmissions('a-1');

        expect(notifier.state.isLoading, isFalse);
        expect(notifier.state.error, isNotNull);
        expect(notifier.state.submissions, isEmpty);
      });
    });

    group('loadSubmissionDetail', () {
      test('populates currentSubmission on success', () async {
        final mockGet = MockGetSubmissionDetail();
        final notifier = _buildNotifier(getSubmissionDetail: mockGet);

        when(() => mockGet(any()))
            .thenAnswer((_) async => Right(tSubmission));

        await notifier.loadSubmissionDetail('s-1');

        expect(notifier.state.isLoading, isFalse);
        expect(notifier.state.currentSubmission, isNotNull);
        expect(notifier.state.currentSubmission!.id, tSubmission.id);
        expect(notifier.state.error, isNull);
      });

      test('sets error on failure', () async {
        final mockGet = MockGetSubmissionDetail();
        final notifier = _buildNotifier(getSubmissionDetail: mockGet);

        when(() => mockGet(any()))
            .thenAnswer((_) async => const Left(ServerFailure('Not found')));

        await notifier.loadSubmissionDetail('s-1');

        expect(notifier.state.isLoading, isFalse);
        expect(notifier.state.error, isNotNull);
      });
    });

    group('gradeSubmission', () {
      test('sets successMessage and updates currentSubmission on success', () async {
        final mockGrade = MockGradeSubmission();
        final notifier = _buildNotifier(gradeSubmission: mockGrade);

        when(() => mockGrade(any())).thenAnswer((_) async =>
            Right(MutationResult(
                entity: tSubmission, status: SyncStatus.pending)));

        await notifier.gradeSubmission(
            GradeSubmissionParams(submissionId: 's-1', score: 90));

        expect(notifier.state.successMessage, isNotNull);
        expect(notifier.state.currentSubmission, isNotNull);
        expect(notifier.state.error, isNull);
      });

      test('sets error on failure', () async {
        final mockGrade = MockGradeSubmission();
        final notifier = _buildNotifier(gradeSubmission: mockGrade);

        when(() => mockGrade(any()))
            .thenAnswer((_) async => const Left(ServerFailure('Grade failed')));

        await notifier.gradeSubmission(
            GradeSubmissionParams(submissionId: 's-1', score: 90));

        expect(notifier.state.error, isNotNull);
        expect(notifier.state.successMessage, isNull);
      });
    });

    group('createSubmission', () {
      test('sets successMessage and currentSubmission on success', () async {
        final mockCreate = MockCreateSubmission();
        final notifier = _buildNotifier(createSubmission: mockCreate);

        when(() => mockCreate(any())).thenAnswer((_) async =>
            Right(MutationResult(
                entity: tSubmission, status: SyncStatus.pending)));

        await notifier.createSubmission(
            CreateSubmissionParams(assignmentId: 'a-1', textContent: 'Hello'));

        expect(notifier.state.successMessage, isNotNull);
        expect(notifier.state.currentSubmission, isNotNull);
      });

      test('sets error on failure', () async {
        final mockCreate = MockCreateSubmission();
        final notifier = _buildNotifier(createSubmission: mockCreate);

        when(() => mockCreate(any()))
            .thenAnswer((_) async => const Left(ServerFailure('Create failed')));

        await notifier.createSubmission(
            CreateSubmissionParams(assignmentId: 'a-1'));

        expect(notifier.state.error, isNotNull);
      });
    });

    group('submitAssignment', () {
      test('sets successMessage on success', () async {
        final mockSubmit = MockSubmitAssignment();
        final notifier = _buildNotifier(submitAssignment: mockSubmit);

        when(() => mockSubmit(any())).thenAnswer((_) async =>
            Right(MutationResult(
                entity: tSubmission, status: SyncStatus.pending)));

        await notifier.submitAssignment('s-1');

        expect(notifier.state.successMessage, isNotNull);
        expect(notifier.state.currentSubmission, isNotNull);
      });

      test('sets error on failure', () async {
        final mockSubmit = MockSubmitAssignment();
        final notifier = _buildNotifier(submitAssignment: mockSubmit);

        when(() => mockSubmit(any()))
            .thenAnswer((_) async => const Left(ServerFailure('Submit failed')));

        await notifier.submitAssignment('s-1');

        expect(notifier.state.error, isNotNull);
      });
    });

    group('returnSubmission', () {
      test('sets successMessage on success', () async {
        final mockReturn = MockReturnSubmission();
        final notifier = _buildNotifier(returnSubmission: mockReturn);

        when(() => mockReturn(any())).thenAnswer((_) async =>
            Right(MutationResult(
                entity: tSubmission, status: SyncStatus.pending)));

        await notifier.returnSubmission('s-1');

        expect(notifier.state.successMessage, isNotNull);
        expect(notifier.state.currentSubmission, isNotNull);
      });
    });

    group('deleteSubmissionFile', () {
      test('removes file from currentSubmission on success', () async {
        final mockDelete = MockDeleteFile();
        final mockGetDetail = MockGetSubmissionDetail();
        final notifier = _buildNotifier(
          deleteFile: mockDelete,
          getSubmissionDetail: mockGetDetail,
        );

        final submissionWithFile = FakeEntities.assignmentSubmission();
        when(() => mockGetDetail(any()))
            .thenAnswer((_) async => Right(submissionWithFile));
        await notifier.loadSubmissionDetail('s-1');

        when(() => mockDelete(any())).thenAnswer((_) async =>
            Right(MutationResult(
                entity: FakeEntities.submissionFile(),
                status: SyncStatus.pending)));

        await notifier.deleteSubmissionFile('file-1');

        expect(notifier.state.successMessage, isNotNull);
        expect(notifier.state.error, isNull);
      });
    });

    group('clearMessages', () {
      test('clears error and successMessage', () {
        final notifier = _buildNotifier();
        notifier.state = notifier.state.copyWith(
          error: 'Some error',
          successMessage: 'Some success',
        );
        notifier.clearMessages();
        expect(notifier.state.error, isNull);
        expect(notifier.state.successMessage, isNull);
      });
    });

    group('initial state', () {
      test('starts empty and not loading', () {
        final notifier = _buildNotifier();
        expect(notifier.state.submissions, isEmpty);
        expect(notifier.state.currentSubmission, isNull);
        expect(notifier.state.isLoading, isFalse);
        expect(notifier.state.error, isNull);
      });
    });
  });
}
