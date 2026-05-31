import 'package:likha/core/utils/typedef.dart';
import 'package:likha/domain/assessments/entities/assessment.dart';
import 'package:likha/domain/assessments/entities/question.dart';
import 'package:likha/data/repositories/assessments/assessment_repository_base.dart';
import 'package:likha/data/repositories/assessments/mixins/operations/query/get_assessments.dart'
    as get_assessments_op;
import 'package:likha/data/repositories/assessments/mixins/operations/query/get_assessment_detail.dart'
    as get_assessment_detail_op;
import 'package:likha/data/repositories/assessments/mixins/operations/query/publish_assessment.dart'
    as publish_assessment_op;
import 'package:likha/data/repositories/assessments/mixins/operations/query/unpublish_assessment.dart'
    as unpublish_assessment_op;
import 'package:likha/data/repositories/assessments/mixins/operations/query/release_results.dart'
    as release_results_op;

mixin AssessmentQueryMixin on AssessmentRepositoryBase {
  @override
  ResultFuture<List<Assessment>> getAssessments({
    required String classId,
    bool publishedOnly = false,
    bool skipBackgroundRefresh = false,
    bool forceRemote = false,
  }) =>
      get_assessments_op.getAssessments(
        this,
        classId: classId,
        publishedOnly: publishedOnly,
        skipBackgroundRefresh: skipBackgroundRefresh,
        forceRemote: forceRemote,
      );

  @override
  ResultFuture<(Assessment, List<Question>)> getAssessmentDetail({
    required String assessmentId,
  }) =>
      get_assessment_detail_op.getAssessmentDetail(this, assessmentId: assessmentId);

  @override
  ResultFuture<Assessment> publishAssessment({
    required String assessmentId,
  }) =>
      publish_assessment_op.publishAssessment(this, assessmentId: assessmentId);

  @override
  ResultFuture<Assessment> unpublishAssessment({
    required String assessmentId,
  }) =>
      unpublish_assessment_op.unpublishAssessment(this, assessmentId: assessmentId);

  @override
  ResultFuture<Assessment> releaseResults({
    required String assessmentId,
  }) =>
      release_results_op.releaseResults(this, assessmentId: assessmentId);
}