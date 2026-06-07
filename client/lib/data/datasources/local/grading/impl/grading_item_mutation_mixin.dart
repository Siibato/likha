import '../grading_local_datasource_base.dart';
import 'operations/grade_item/update_item_fields.dart';
import 'operations/grade_item/soft_delete_item.dart';

mixin GradingItemMutationMixin on GradingLocalDataSourceBase {
  @override
  Future<void> updateItemFields(String id, Map<String, dynamic> data) async {
    return updateItemFieldsOp(localDatabase, syncQueue, id, data);
  }

  @override
  Future<void> softDeleteItem(String id) async {
    return softDeleteItemOp(localDatabase, syncQueue, id);
  }
}
