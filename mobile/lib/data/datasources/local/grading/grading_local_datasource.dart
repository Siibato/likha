import 'package:likha/data/models/grading/grade_config_model.dart';
import 'package:likha/data/models/grading/grade_item_model.dart';
import 'package:likha/data/models/grading/grade_score_model.dart';
import 'package:likha/data/models/grading/period_grade_model.dart';

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
  Future<GradeItemModel?> getItemBySourceId(String sourceId);

  // Grade Scores
  Future<List<GradeScoreModel>> getScoresByItem(String gradeItemId);
  Future<void> saveScores(List<GradeScoreModel> scores);
  Future<void> upsertScoresByItem(
      String gradeItemId, List<GradeScoreModel> scores);
  Future<void> updateScoreOverride(String scoreId, double? overrideScore);

  // Period Grades
  Future<List<PeriodGradeModel>> getPeriodGradesByClass(
    String classId,
    int gradingPeriodNumber,
  );
  Future<List<PeriodGradeModel>> getStudentAllPeriods(
    String classId,
    String studentId,
  );
  Future<void> savePeriodGrades(List<PeriodGradeModel> grades);
  Future<void> updateTransmutedGrade(
    String classId,
    String studentId,
    int gradingPeriodNumber,
    int transmutedGrade,
  );
}
