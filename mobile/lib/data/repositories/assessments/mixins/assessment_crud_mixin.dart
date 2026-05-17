import 'package:likha/core/utils/typedef.dart';
import 'package:likha/domain/assessments/entities/assessment.dart';
import 'package:likha/data/repositories/assessments/assessment_repository_base.dart';
import 'package:likha/data/repositories/assessments/mixins/operations/crud/create_assessment.dart'
    as create_assessment_op;
import 'package:likha/data/repositories/assessments/mixins/operations/crud/update_assessment.dart'
    as update_assessment_op;
import 'package:likha/data/repositories/assessments/mixins/operations/crud/delete_assessment.dart'
    as delete_assessment_op;
import 'package:likha/data/repositories/assessments/mixins/operations/crud/reorder_all_assessments.dart'
    as reorder_all_assessments_op;

mixin AssessmentCrudMixin on AssessmentRepositoryBase {
  @override
  ResultFuture<Assessment> createAssessment({
    required String classId,
    required String title,
    String? description,
    required int timeLimitMinutes,
    required String openAt,
    required String closeAt,
    bool? showResultsImmediately,
    bool isPublished = false,
    List<Map<String, dynamic>>? questions,
    int? gradingPeriodNumber,
    String? component,
    String? tosId,
  }) =>
      create_assessment_op.createAssessment(
        this,
        classId: classId,
        title: title,
        description: description,
        timeLimitMinutes: timeLimitMinutes,
        openAt: openAt,
        closeAt: closeAt,
        showResultsImmediately: showResultsImmediately,
        isPublished: isPublished,
        questions: questions,
        gradingPeriodNumber: gradingPeriodNumber,
        component: component,
        tosId: tosId,
      );

  @override
  ResultFuture<Assessment> updateAssessment({
    required String assessmentId,
    String? title,
    String? description,
    int? timeLimitMinutes,
    String? openAt,
    String? closeAt,
    bool? showResultsImmediately,
    int? gradingPeriodNumber,
    String? component,
  }) =>
      update_assessment_op.updateAssessment(
        this,
        assessmentId: assessmentId,
        title: title,
        description: description,
        timeLimitMinutes: timeLimitMinutes,
        openAt: openAt,
        closeAt: closeAt,
        showResultsImmediately: showResultsImmediately,
        gradingPeriodNumber: gradingPeriodNumber,
        component: component,
      );

  @override
  ResultVoid deleteAssessment({required String assessmentId}) =>
      delete_assessment_op.deleteAssessment(this, assessmentId: assessmentId);

  @override
  ResultVoid reorderAllAssessments({
    required String classId,
    required List<String> assessmentIds,
  }) =>
      reorder_all_assessments_op.reorderAllAssessments(
        this,
        classId: classId,
        assessmentIds: assessmentIds,
      );
}