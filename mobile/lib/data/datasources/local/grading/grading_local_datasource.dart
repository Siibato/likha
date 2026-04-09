import 'package:likha/data/models/grading/grade_config_model.dart';
import 'package:likha/data/models/grading/grade_item_model.dart';
import 'package:likha/data/models/grading/grade_score_model.dart';
import 'package:likha/data/models/grading/quarterly_grade_model.dart';

abstract class GradingLocalDataSource {
  // Config
  Future<List<GradeConfigModel>> getConfigByClass(String classId);
  Future<void> saveConfigs(List<GradeConfigModel> configs);

  // Grade Items
  Future<List<GradeItemModel>> getItemsByClassQuarter(
    String classId,
    int quarter, {
    String? component,
  });
  Future<void> saveItems(List<GradeItemModel> items);
  Future<void> saveItem(GradeItemModel item);
  Future<void> deleteItem(String id);

  // Grade Item mutations
  Future<void> updateItemFields(String id, Map<String, dynamic> data);
  Future<void> softDeleteItem(String id);

  // Scores
  Future<List<GradeScoreModel>> getScoresByItem(String gradeItemId);
  Future<void> saveScores(List<GradeScoreModel> scores);
  Future<void> upsertScoresByItem(
      String gradeItemId, List<GradeScoreModel> scores);
  Future<void> updateScoreOverride(String scoreId, double? overrideScore);

  // Quarterly Grades
  Future<List<QuarterlyGradeModel>> getQuarterlyGradesByClass(
    String classId,
    int quarter,
  );
  Future<List<QuarterlyGradeModel>> getStudentAllQuarters(
    String classId,
    String studentId,
  );
  Future<void> saveQuarterlyGrades(List<QuarterlyGradeModel> grades);
  Future<void> updateTransmutedGrade(
    String classId,
    String studentId,
    int quarter,
    int transmutedGrade,
  );
}
