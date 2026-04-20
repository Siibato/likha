import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';

import 'package:likha/core/errors/failures.dart';
import 'package:likha/core/events/data_event_bus.dart';
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
        )).thenAnswer((_) async => Right(FakeEntities.gradeItem()));
    GetIt.instance.registerSingleton<GradingRepository>(mockGradingRepo);
    registerFallbackValue(CreateAssessmentParams(
      classId: 'c-1',
      title: 'Test',
      timeLimitMinutes: 60,
      openAt: '2025-01-01T00:00:00',
      closeAt: '2025-12-31T00:00:00',
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
            .thenAnswer((_) async => const Right(null));

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
  });
}
