import 'package:likha/core/database/local_database.dart';
import 'package:likha/core/sync/sync_queue.dart';
import '../class_local_datasource_base.dart';
import 'class_cache_mixin.dart';
import 'class_participant_mixin.dart';
import 'class_mutation_mixin.dart';
import 'class_query_mixin.dart';
import 'class_student_search_mixin.dart';

class ClassLocalDataSourceImpl extends ClassLocalDataSourceBase
    with
        ClassQueryMixin,
        ClassCacheMixin,
        ClassMutationMixin,
        ClassParticipantMixin,
        ClassStudentSearchMixin {
  @override
  final LocalDatabase localDatabase;

  @override
  final SyncQueue syncQueue;

  ClassLocalDataSourceImpl(this.localDatabase, this.syncQueue);
}