import 'package:likha/data/models/assessments/assessment_model.dart';
import 'package:likha/data/models/assessments/question_model.dart';
import '../assessment_local_datasource_base.dart';
import 'operations/query/get_cached_assessments.dart';
import 'operations/query/get_cached_assessment_detail.dart';

mixin AssessmentQueryMixin on AssessmentLocalDataSourceBase {
  @override
  Future<List<AssessmentModel>> getCachedAssessments(String classId, {bool publishedOnly = false}) async {
    return getCachedAssessmentsOp(localDatabase, classId, publishedOnly: publishedOnly);
  }

  @override
  Future<(AssessmentModel, List<QuestionModel>)> getCachedAssessmentDetail(String assessmentId) async {
    return getCachedAssessmentDetailOp(localDatabase, assessmentId);
  }
}
