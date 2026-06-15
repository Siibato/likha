import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';

import 'package:likha/core/errors/failures.dart';
import 'package:likha/core/events/data_event_bus.dart';
import 'package:likha/core/sync/mutation_result.dart';
import 'package:likha/core/sync/sync_queue.dart';
import 'package:likha/domain/grading/repositories/grading_repository.dart';
import 'package:likha/domain/grading/entities/grade_item.dart';
import 'package:likha/domain/assessments/usecases/add_questions.dart';
import 'package:likha/domain/assessments/usecases/create_assessment.dart';
import 'package:likha/domain/assessments/usecases/delete_assessment.dart';
import 'package:likha/domain/assessments/usecases/delete_question.dart';
import 'package:likha/domain/assessments/usecases/get_assessment_detail.dart';
import 'package:likha/domain/assessments/usecases/get_assessments.dart';
import 'package:likha/domain/assessments/usecases/get_statistics.dart';
import 'package:likha/domain/assessments/usecases/get_submission_detail.dart';
import 'package:likha/domain/assessments/usecases/get_submissions.dart';
import 'package:likha/domain/assessments/usecases/grade_essay.dart';
import 'package:likha/domain/assessments/usecases/override_answer.dart';
import 'package:likha/domain/assessments/usecases/publish_assessment.dart';
import 'package:likha/domain/assessments/usecases/release_results.dart';
import 'package:likha/domain/assessments/usecases/reorder_assessment.dart';
import 'package:likha/domain/assessments/usecases/reorder_questions.dart';
import 'package:likha/domain/assessments/usecases/unpublish_assessment.dart';
import 'package:likha/domain/assessments/usecases/update_assessment.dart';
import 'package:likha/domain/assessments/usecases/update_question.dart';
import 'package:likha/presentation/providers/teacher_assessment_provider.dart';

import '../../../helpers/fake_entities.dart';

// ── Mocks ─────────────────────────────────────────────────────────────────────

class MockCreateAssessment extends Mock implements CreateAssessment {}
class MockGetAssessments extends Mock implements GetAssessments {}
class MockGetAssessmentDetail extends Mock implements GetAssessmentDetail {}
class MockPublishAssessment extends Mock implements PublishAssessment {}
class MockUnpublishAssessment extends Mock implements UnpublishAssessment {}
class MockDeleteAssessment extends Mock implements DeleteAssessment {}
class MockAddQuestions extends Mock implements AddQuestions {}
class MockGetSubmissions extends Mock implements GetSubmissions {}
class MockGetSubmissionDetail extends Mock implements GetSubmissionDetail {}
class MockOverrideAnswer extends Mock implements OverrideAnswer {}
class MockGradeEssay extends Mock implements GradeEssay {}
class MockReleaseResults extends Mock implements ReleaseResults {}
class MockGetStatistics extends Mock implements GetStatistics {}
class MockUpdateAssessment extends Mock implements UpdateAssessment {}
class MockUpdateQuestion extends Mock implements UpdateQuestion {}
class MockDeleteQuestion extends Mock implements DeleteQuestion {}
class MockReorderAllQuestions extends Mock implements ReorderAllQuestions {}
class MockReorderAllAssessments extends Mock implements ReorderAllAssessments {}
class MockGradingRepository extends Mock implements GradingRepository {
  @override
  Future<Either<Failure, GradeItem?>> findGradeItemBySourceId(String sourceId) async {
    return const Right(null);
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────

TeacherAssessmentNotifier _buildNotifier({
  MockGetAssessments? getAssessments,
  MockCreateAssessment? createAssessment,
  MockDeleteAssessment? deleteAssessment,
}) {
  return TeacherAssessmentNotifier(
    createAssessment ?? MockCreateAssessment(),
    getAssessments ?? MockGetAssessments(),
    MockGetAssessmentDetail(),
    MockPublishAssessment(),
    MockUnpublishAssessment(),
    deleteAssessment ?? MockDeleteAssessment(),
    MockAddQuestions(),
    MockGetSubmissions(),
    MockGetSubmissionDetail(),
    MockOverrideAnswer(),
    MockGradeEssay(),
    MockReleaseResults(),
    MockGetStatistics(),
    MockUpdateAssessment(),
    MockUpdateQuestion(),
    MockDeleteQuestion(),
    MockReorderAllQuestions(),
    MockReorderAllAssessments(),
  );
}

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  final tAssessment = FakeEntities.assessment();

  setUpAll(() {
    GetIt.instance.registerSingleton<DataEventBus>(DataEventBus());
    final mockGradingRepo = MockGradingRepository();
    when(() => mockGradingRepo.createGradeItem(
          classId: any(named: 'classId'),
          data: any(named: 'data'),
        )).thenAnswer((_) async => Right(MutationResult(entity: FakeEntities.gradeItem(), status: SyncStatus.pending)));
    GetIt.instance.registerSingleton<GradingRepository>(mockGradingRepo);
    registerFallbackValue(CreateAssessmentParams(
      classId: 'c-1',
      title: 'Test',
      timeLimitMinutes: 60,
      openAt: '2025-01-01T00:00:00',
      closeAt: '2025-12-31T00:00:00',
    ));
    registerFallbackValue(AddQuestionsParams(
      assessmentId: 'a-1',
      questions: [],
    ));
    registerFallbackValue(UpdateAssessmentParams(
      assessmentId: 'a-1',
    ));
  });

  tearDownAll(() async {
    await GetIt.instance.reset();
  });

  group('TeacherAssessmentNotifier', () {
    group('loadAssessments', () {
      test('populates assessments on success', () async {
        final mockGet = MockGetAssessments();
        final notifier = _buildNotifier(getAssessments: mockGet);

        when(() => mockGet(
              any(),
              publishedOnly: any(named: 'publishedOnly'),
              skipBackgroundRefresh: any(named: 'skipBackgroundRefresh'),
            )).thenAnswer((_) async => Right([tAssessment]));

        final states = <TeacherAssessmentState>[];
        notifier.addListener((s) => states.add(s), fireImmediately: false);

        await notifier.loadAssessments('c-1');

        expect(states.last.isLoading, isFalse);
        expect(states.last.assessments.length, 1);
        expect(states.last.error, isNull);
      });

      test('sets error on failure', () async {
        final mockGet = MockGetAssessments();
        final notifier = _buildNotifier(getAssessments: mockGet);

        when(() => mockGet(
              any(),
              publishedOnly: any(named: 'publishedOnly'),
              skipBackgroundRefresh: any(named: 'skipBackgroundRefresh'),
            )).thenAnswer((_) async => const Left(ServerFailure('error')));

        final states = <TeacherAssessmentState>[];
        notifier.addListener((s) => states.add(s), fireImmediately: false);

        await notifier.loadAssessments('c-1');

        expect(states.last.isLoading, isFalse);
        expect(states.last.error, isNotNull);
      });
    });

    group('deleteAssessment', () {
      test('removes assessment from state on success', () async {
        final mockDelete = MockDeleteAssessment();
        final notifier = _buildNotifier(deleteAssessment: mockDelete);

        notifier.state = notifier.state.copyWith(assessments: [tAssessment]);

        when(() => mockDelete(any()))
            .thenAnswer((_) async => const Right(MutationResult(entity: null, status: SyncStatus.pending)));

        final states = <TeacherAssessmentState>[];
        notifier.addListener((s) => states.add(s), fireImmediately: false);

        await notifier.deleteAssessment(tAssessment.id);

        expect(states.last.assessments, isEmpty);
        expect(states.last.error, isNull);
      });

      test('sets error when delete fails', () async {
        final mockDelete = MockDeleteAssessment();
        final notifier = _buildNotifier(deleteAssessment: mockDelete);

        notifier.state = notifier.state.copyWith(assessments: [tAssessment]);

        when(() => mockDelete(any()))
            .thenAnswer((_) async => const Left(ServerFailure('delete failed')));

        final states = <TeacherAssessmentState>[];
        notifier.addListener((s) => states.add(s), fireImmediately: false);

        await notifier.deleteAssessment(tAssessment.id);

        expect(states.last.error, isNotNull);
      });
    });

    group('createAssessment', () {
      test('shows optimistic assessment immediately without loading spinner', () async {
        final mockCreate = MockCreateAssessment();
        final notifier = _buildNotifier(createAssessment: mockCreate);

        final optimistic = FakeEntities.assessment(id: 'new-a', title: 'New');
        when(() => mockCreate(any())).thenAnswer(
          (_) async => Right(MutationResult(entity: optimistic, status: SyncStatus.pending)),
        );

        final states = <TeacherAssessmentState>[];
        notifier.addListener((s) => states.add(s), fireImmediately: false);

        final result = await notifier.createAssessment(CreateAssessmentParams(
          classId: 'c-1',
          title: 'New',
          timeLimitMinutes: 60,
          openAt: '2025-01-01T00:00:00',
          closeAt: '2025-12-31T00:00:00',
        ));

        expect(result, isNotNull);
        expect(states.last.assessments.length, 1);
        expect(states.last.assessments.first.title, 'New');
        expect(states.last.isLoading, isFalse);
        expect(states.last.error, isNull);
      });

      test('rolls back state on failure', () async {
        final mockCreate = MockCreateAssessment();
        final notifier = _buildNotifier(createAssessment: mockCreate);

        when(() => mockCreate(any())).thenAnswer(
          (_) async => const Left(ServerFailure('create failed')),
        );

        final previous = notifier.state;
        final states = <TeacherAssessmentState>[];
        notifier.addListener((s) => states.add(s), fireImmediately: false);

        await notifier.createAssessment(CreateAssessmentParams(
          classId: 'c-1',
          title: 'New',
          timeLimitMinutes: 60,
          openAt: '2025-01-01T00:00:00',
          closeAt: '2025-12-31T00:00:00',
        ));

        expect(states.last.error, isNotNull);
        expect(states.last.assessments, previous.assessments);
        expect(states.last.isLoading, isFalse);
      });
    });

    group('publishAssessment', () {
      test('shows optimistic published state immediately without loading spinner', () async {
        final mockPublish = MockPublishAssessment();
        // Inject mock by building manually
        final notifier2 = TeacherAssessmentNotifier(
          MockCreateAssessment(),
          MockGetAssessments(),
          MockGetAssessmentDetail(),
          mockPublish,
          MockUnpublishAssessment(),
          MockDeleteAssessment(),
          MockAddQuestions(),
          MockGetSubmissions(),
          MockGetSubmissionDetail(),
          MockOverrideAnswer(),
          MockGradeEssay(),
          MockReleaseResults(),
          MockGetStatistics(),
          MockUpdateAssessment(),
          MockUpdateQuestion(),
          MockDeleteQuestion(),
          MockReorderAllQuestions(),
          MockReorderAllAssessments(),
        );

        notifier2.state = notifier2.state.copyWith(
          assessments: [tAssessment],
          currentAssessment: tAssessment,
        );

        final published = FakeEntities.assessment(
          id: tAssessment.id,
          isPublished: true,
        );
        when(() => mockPublish(any())).thenAnswer(
          (_) async => Right(MutationResult(entity: published, status: SyncStatus.pending)),
        );

        final states = <TeacherAssessmentState>[];
        notifier2.addListener((s) => states.add(s), fireImmediately: false);

        await notifier2.publishAssessment(tAssessment.id);

        expect(states.last.currentAssessment?.isPublished, isTrue);
        expect(states.last.assessments.first.isPublished, isTrue);
        expect(states.last.isLoading, isFalse);
        expect(states.last.error, isNull);
      });
    });

    group('updateAssessment', () {
      test('shows optimistic updated state immediately without loading spinner', () async {
        final mockUpdate = MockUpdateAssessment();
        final notifier = TeacherAssessmentNotifier(
          MockCreateAssessment(),
          MockGetAssessments(),
          MockGetAssessmentDetail(),
          MockPublishAssessment(),
          MockUnpublishAssessment(),
          MockDeleteAssessment(),
          MockAddQuestions(),
          MockGetSubmissions(),
          MockGetSubmissionDetail(),
          MockOverrideAnswer(),
          MockGradeEssay(),
          MockReleaseResults(),
          MockGetStatistics(),
          mockUpdate,
          MockUpdateQuestion(),
          MockDeleteQuestion(),
          MockReorderAllQuestions(),
          MockReorderAllAssessments(),
        );

        notifier.state = notifier.state.copyWith(
          assessments: [tAssessment],
          currentAssessment: tAssessment,
        );

        final updated = FakeEntities.assessment(
          id: tAssessment.id,
          title: 'Updated Title',
        );
        when(() => mockUpdate(any())).thenAnswer(
          (_) async => Right(MutationResult(entity: updated, status: SyncStatus.pending)),
        );

        final states = <TeacherAssessmentState>[];
        notifier.addListener((s) => states.add(s), fireImmediately: false);

        await notifier.updateAssessment(UpdateAssessmentParams(
          assessmentId: tAssessment.id,
          title: 'Updated Title',
        ));

        expect(states.last.currentAssessment?.title, 'Updated Title');
        expect(states.last.assessments.first.title, 'Updated Title');
        expect(states.last.isLoading, isFalse);
        expect(states.last.error, isNull);
      });
    });

    group('addQuestions', () {
      test('shows optimistic questions immediately without loading spinner', () async {
        final mockAdd = MockAddQuestions();
        final notifier = TeacherAssessmentNotifier(
          MockCreateAssessment(),
          MockGetAssessments(),
          MockGetAssessmentDetail(),
          MockPublishAssessment(),
          MockUnpublishAssessment(),
          MockDeleteAssessment(),
          mockAdd,
          MockGetSubmissions(),
          MockGetSubmissionDetail(),
          MockOverrideAnswer(),
          MockGradeEssay(),
          MockReleaseResults(),
          MockGetStatistics(),
          MockUpdateAssessment(),
          MockUpdateQuestion(),
          MockDeleteQuestion(),
          MockReorderAllQuestions(),
          MockReorderAllAssessments(),
        );

        notifier.state = notifier.state.copyWith(
          currentAssessment: tAssessment,
        );

        final newQuestions = [
          FakeEntities.multipleChoiceQuestion(id: 'q1'),
          FakeEntities.essayQuestion(id: 'q2'),
        ];
        when(() => mockAdd(any())).thenAnswer(
          (_) async => Right(MutationResult(entity: newQuestions, status: SyncStatus.pending)),
        );

        final states = <TeacherAssessmentState>[];
        notifier.addListener((s) => states.add(s), fireImmediately: false);

        await notifier.addQuestions(AddQuestionsParams(
          assessmentId: tAssessment.id,
          questions: [
            {'question_type': 'multiple_choice', 'question_text': 'Q1', 'points': 1},
            {'question_type': 'essay', 'question_text': 'Q2', 'points': 5},
          ],
        ));

        expect(states.last.questions.length, 2);
        expect(states.last.isLoading, isFalse);
        expect(states.last.error, isNull);
      });
    });
  });
}
