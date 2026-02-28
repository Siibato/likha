import 'package:likha/core/database/local_database.dart';
import 'package:likha/core/sync/sync_queue.dart';
import '../assignment_local_datasource_base.dart';
import 'assignment_cache_mixin.dart';
import 'assignment_clear_mixin.dart';
import 'assignment_file_mixin.dart';
import 'assignment_mutation_mixin.dart';
import 'assignment_query_mixin.dart';

class AssignmentLocalDataSourceImpl extends AssignmentLocalDataSourceBase
    with
        AssignmentQueryMixin,
        AssignmentCacheMixin,
        AssignmentMutationMixin,
        AssignmentFileMixin,
        AssignmentClearMixin {
  @override
  final LocalDatabase localDatabase;

  @override
  final SyncQueue syncQueue;

  AssignmentLocalDataSourceImpl(this.localDatabase, this.syncQueue);
}