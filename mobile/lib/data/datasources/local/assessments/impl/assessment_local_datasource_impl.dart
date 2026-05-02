import 'package:likha/core/database/local_database.dart';
import 'package:likha/core/security/encryption_service.dart';
import 'package:likha/core/sync/sync_queue.dart';
import '../assessment_local_datasource_base.dart';
import 'assessment_cache_mixin.dart';
import 'assessment_create_mixin.dart';
import 'assessment_query_mixin.dart';
import 'question_datasource_mixin.dart';
import 'statistics_datasource_mixin.dart';
import 'submission_datasource_mixin.dart';

class AssessmentLocalDataSourceImpl extends AssessmentLocalDataSourceBase
    with
        AssessmentQueryMixin,
        AssessmentCacheMixin,
        AssessmentCreateMixin,
        QuestionDataSourceMixin,
        SubmissionDataSourceMixin,
        StatisticsDataSourceMixin {
  @override
  final LocalDatabase localDatabase;

  @override
  final SyncQueue syncQueue;

  @override
  final EncryptionService enc;

  AssessmentLocalDataSourceImpl(this.localDatabase, this.syncQueue, this.enc);
}