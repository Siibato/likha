import 'package:likha/data/models/grading/grade_item_model.dart';
import '../grading_local_datasource_base.dart';
import 'operations/grade_item/get_items_by_class_quarter.dart';
import 'operations/grade_item/save_items.dart';
import 'operations/grade_item/save_item.dart';
import 'operations/grade_item/get_item_by_source_id.dart';

mixin GradingItemQueryMixin on GradingLocalDataSourceBase {
  @override
  Future<List<GradeItemModel>> getItemsByClassQuarter(
    String classId,
    int quarter, {
    String? component,
  }) async {
    return getItemsByClassQuarterOp(localDatabase, classId, quarter, component: component);
  }

  @override
  Future<void> saveItems(List<GradeItemModel> items) async {
    return saveItemsOp(localDatabase, items);
  }

  @override
  Future<void> saveItem(GradeItemModel item) async {
    return saveItemOp(localDatabase, item);
  }

  @override
  Future<GradeItemModel?> getItemBySourceId(String sourceId) async {
    return getItemBySourceIdOp(localDatabase, sourceId);
  }
}
