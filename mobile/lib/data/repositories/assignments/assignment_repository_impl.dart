import 'package:likha/data/repositories/assignments/assignment_repository_base.dart';
import 'mixins/assignment_crud_mixin.dart';
import 'mixins/assignment_query_mixin.dart';
import 'mixins/assignment_submission_mixin.dart';

class AssignmentRepositoryImpl extends AssignmentRepositoryBase
    with
        AssignmentCrudMixin,
        AssignmentQueryMixin,
        AssignmentSubmissionMixin {

  AssignmentRepositoryImpl({
    required super.remoteDataSource,
    required super.localDataSource,
    required super.validationService,
    required super.connectivityService,
    required super.syncQueue,
    required super.serverReachabilityService,
    required super.storageService,
  });
}