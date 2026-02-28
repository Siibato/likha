import 'package:likha/core/errors/exceptions.dart';
import 'package:likha/data/models/learning_materials/learning_material_model.dart';
import '../learning_material_local_datasource_base.dart';

mixin LearningMaterialQueryMixin on LearningMaterialLocalDataSourceBase {
  @override
  Future<List<LearningMaterialModel>> getCachedMaterials(String classId) async {
    try {
      final db = await localDatabase.database;
      final results = await db.query(
        'learning_materials',
        where: 'class_id = ?',
        whereArgs: [classId],
        orderBy: 'order_index ASC',
      );
      if (results.isEmpty) throw CacheException('No cached materials for class $classId');
      return results.map((r) => LearningMaterialModel.fromMap(r)).toList();
    } catch (e) {
      if (e is CacheException) rethrow;
      throw CacheException(e.toString());
    }
  }

  @override
  Future<LearningMaterialModel> getCachedMaterialDetail(String materialId) async {
    try {
      final db = await localDatabase.database;
      final results = await db.query(
        'learning_materials',
        where: 'id = ?',
        whereArgs: [materialId],
      );
      if (results.isEmpty) throw CacheException('Material $materialId not cached');
      return LearningMaterialModel.fromMap(results.first);
    } catch (e) {
      if (e is CacheException) rethrow;
      throw CacheException(e.toString());
    }
  }
}