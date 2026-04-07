import 'package:likha/core/database/local_database.dart';
import 'package:likha/core/sync/sync_queue.dart';
import '../tos_local_datasource_base.dart';
import 'tos_cache_mixin.dart';
import 'tos_query_mixin.dart';
import 'tos_mutation_mixin.dart';

class TosLocalDataSourceImpl extends TosLocalDataSourceBase
    with TosCacheMixin, TosQueryMixin, TosMutationMixin {
  @override
  final LocalDatabase localDatabase;

  @override
  final SyncQueue syncQueue;

  TosLocalDataSourceImpl(this.localDatabase, this.syncQueue);
}
