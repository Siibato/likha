import 'package:likha/data/repositories/classes/class_repository_base.dart';
import 'mixins/class_crud_mixin.dart';
import 'mixins/class_query_mixin.dart';
import 'mixins/class_participant_mixin.dart';

class ClassRepositoryImpl extends ClassRepositoryBase
    with
        ClassCrudMixin,
        ClassQueryMixin,
        ClassParticipantMixin {
  ClassRepositoryImpl({
    required super.remoteDataSource,
    required super.localDataSource,
    required super.validationService,
    required super.serverReachabilityService,
    required super.syncQueue,
    required super.storageService,
    required super.dataEventBus,
  });
}