import 'package:likha/data/models/assessments/question_model.dart';
import '../assessment_local_datasource_base.dart';
import 'operations/create/create_assessment_locally.dart';
import 'operations/create/create_assessment_with_questions_locally.dart';
import 'operations/create/mark_assessment_published_locally.dart';
import 'operations/create/mark_assessment_unpublished_locally.dart';

mixin AssessmentCreateMixin on AssessmentLocalDataSourceBase {
  @override
  Future<String> createAssessmentLocally({
    required String classId,
    required String title,
    String? description,
    required int timeLimitMinutes,
    required String openAt,
    required String closeAt,
    bool? showResultsImmediately,
    bool isPublished = true,
    String? tosId,
    int? gradingPeriodNumber,
    String? component,
  }) async {
    return createAssessmentLocallyOp(
      localDatabase,
      syncQueue,
      classId,
      title,
      description,
      timeLimitMinutes,
      openAt,
      closeAt,
      showResultsImmediately,
      isPublished,
      tosId,
      gradingPeriodNumber,
      component,
    );
  }

  @override
  Future<String> createAssessmentWithQuestionsLocally({
    required String classId,
    required String title,
    String? description,
    required int timeLimitMinutes,
    required String openAt,
    required String closeAt,
    bool? showResultsImmediately,
    required List<QuestionModel> questions,
    bool isPublished = true,
    String? linkedTosId,
    int? quarter,
    String? component,
  }) async {
    return createAssessmentWithQuestionsLocallyOp(
      localDatabase,
      syncQueue,
      enc,
      classId,
      title,
      description,
      timeLimitMinutes,
      openAt,
      closeAt,
      showResultsImmediately,
      questions,
      isPublished,
      linkedTosId,
      quarter,
      component,
    );
  }

  @override
  Future<void> markAssessmentPublishedLocally({required String assessmentId}) async {
    return markAssessmentPublishedLocallyOp(localDatabase, assessmentId);
  }

  @override
  Future<void> markAssessmentUnpublishedLocally({required String assessmentId}) async {
    return markAssessmentUnpublishedLocallyOp(localDatabase, assessmentId);
  }
}
