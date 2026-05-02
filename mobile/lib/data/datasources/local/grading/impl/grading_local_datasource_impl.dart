import 'package:likha/core/database/local_database.dart';
import 'package:likha/core/sync/sync_queue.dart';
import '../grading_local_datasource_base.dart';
import 'grading_clear_mixin.dart';
import 'grading_config_mixin.dart';
import 'grading_item_query_mixin.dart';
import 'grading_item_mutation_mixin.dart';
import 'grading_score_mixin.dart';
import 'grading_period_mixin.dart';

class GradingLocalDataSourceImpl extends GradingLocalDataSourceBase
    with
        GradingClearMixin,
        GradingConfigMixin,
        GradingItemQueryMixin,
        GradingItemMutationMixin,
        GradingScoreMixin,
        GradingPeriodMixin {
  @override
  final LocalDatabase localDatabase;

  @override
  final SyncQueue syncQueue;

  GradingLocalDataSourceImpl(this.localDatabase, this.syncQueue);
}
