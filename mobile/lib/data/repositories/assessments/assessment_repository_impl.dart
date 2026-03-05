import 'package:likha/data/repositories/assessments/assessment_repository_base.dart';
import 'mixins/assessment_crud_mixin.dart';
import 'mixins/assessment_query_mixin.dart';
import 'mixins/assessment_question_mixin.dart';
import 'mixins/assessment_submission_mixin.dart';

class AssessmentRepositoryImpl extends AssessmentRepositoryBase
    with
        AssessmentCrudMixin,
        AssessmentQueryMixin,
        AssessmentQuestionMixin,
        AssessmentSubmissionMixin {

  AssessmentRepositoryImpl({
    required super.remoteDataSource,
    required super.localDataSource,
    required super.validationService,
    required super.connectivityService,
    required super.syncQueue,
    required super.serverReachabilityService,
    required super.storageService,
    required super.dataEventBus,
  });
}