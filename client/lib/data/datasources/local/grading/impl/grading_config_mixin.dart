import 'package:likha/data/models/grading/grade_config_model.dart';
import '../grading_local_datasource_base.dart';
import 'operations/config/get_config_by_class.dart';
import 'operations/config/save_configs.dart';

mixin GradingConfigMixin on GradingLocalDataSourceBase {
  @override
  Future<List<GradeConfigModel>> getConfigByClass(String classId) async {
    return getConfigByClassOp(localDatabase, classId);
  }

  @override
  Future<void> saveConfigs(List<GradeConfigModel> configs) async {
    return saveConfigsOp(localDatabase, configs);
  }
}
