import 'package:likha/core/database/local_database.dart';
import 'package:likha/core/sync/sync_queue.dart';
import 'package:likha/data/models/grading/grade_config_model.dart';
import 'package:likha/data/models/grading/grade_item_model.dart';
import 'package:likha/data/models/grading/grade_score_model.dart';
import 'package:likha/data/models/grading/period_grade_model.dart';
import 'operations/grading.dart' as ops;

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

  Future<List<Map<String, dynamic>>> getCachedGradeSummary(
    String classId,
    int gradingPeriodNumber,
  );
  Future<void> cacheGradeSummary(
    String classId,
    int gradingPeriodNumber,
    List<Map<String, dynamic>> summary,
  );

  // Final Grades Cache
  Future<List<Map<String, dynamic>>> getCachedFinalGrades(String classId);
  Future<void> cacheFinalGrades(String classId, List<Map<String, dynamic>> data);

  // General Averages Cache
  Future<Map<String, dynamic>> getCachedGeneralAverages(String classId);
  Future<void> cacheGeneralAverages(String classId, Map<String, dynamic> data);

  // My Grade Detail Cache
  Future<Map<String, dynamic>> getCachedMyGradeDetail(
    String classId,
    int gradingPeriodNumber,
  );
  Future<void> cacheMyGradeDetail(
    String classId,
    int gradingPeriodNumber,
    Map<String, dynamic> data,
  );

  // SF9 Cache
  Future<Map<String, dynamic>> getCachedSf9(String classId, String studentId);
  Future<void> cacheSf9(String classId, String studentId, Map<String, dynamic> data);

  // SF10 Cache
  Future<Map<String, dynamic>> getCachedSf10(String classId, String studentId);
  Future<void> cacheSf10(String classId, String studentId, Map<String, dynamic> data);

  Future<void> clearAllCache();
}

class GradingLocalDataSourceImpl implements GradingLocalDataSource {
  final LocalDatabase localDatabase;
  final SyncQueue syncQueue;

  GradingLocalDataSourceImpl(this.localDatabase, this.syncQueue);

  @override
  Future<List<GradeConfigModel>> getConfigByClass(String classId) =>
      ops.getConfigByClass(localDatabase, classId);

  @override
  Future<void> saveConfigs(List<GradeConfigModel> configs) =>
      ops.saveConfigs(localDatabase, configs);

  @override
  Future<List<GradeItemModel>> getItemsByClassQuarter(
    String classId,
    int quarter, {
    String? component,
  }) =>
      ops.getItemsByClassQuarter(localDatabase, classId, quarter, component: component);

  @override
  Future<void> saveItems(List<GradeItemModel> items) =>
      ops.saveItems(localDatabase, items);

  @override
  Future<void> saveItem(GradeItemModel item) =>
      ops.saveItem(localDatabase, item);

  @override
  Future<void> updateItemFields(String id, Map<String, dynamic> data) =>
      ops.updateItemFields(localDatabase, syncQueue, id, data);

  @override
  Future<void> softDeleteItem(String id) =>
      ops.softDeleteItem(localDatabase, syncQueue, id);

  @override
  Future<GradeItemModel?> getItemBySourceId(String sourceId) =>
      ops.getItemBySourceId(localDatabase, sourceId);

  @override
  Future<List<GradeScoreModel>> getScoresByItem(String gradeItemId) =>
      ops.getScoresByItem(localDatabase, gradeItemId);

  @override
  Future<void> saveScores(List<GradeScoreModel> scores) =>
      ops.saveScores(localDatabase, scores);

  @override
  Future<void> upsertScoresByItem(
    String gradeItemId,
    List<GradeScoreModel> scores,
  ) =>
      ops.upsertScoresByItem(localDatabase, syncQueue, gradeItemId, scores);

  @override
  Future<void> updateScoreOverride(String scoreId, double? overrideScore) =>
      ops.updateScoreOverride(localDatabase, syncQueue, scoreId, overrideScore);

  @override
  Future<List<PeriodGradeModel>> getPeriodGradesByClass(
    String classId,
    int gradingPeriodNumber,
  ) =>
      ops.getPeriodGradesByClass(localDatabase, classId, gradingPeriodNumber);

  @override
  Future<List<PeriodGradeModel>> getStudentAllPeriods(
    String classId,
    String studentId,
  ) =>
      ops.getStudentAllPeriods(localDatabase, classId, studentId);

  @override
  Future<void> savePeriodGrades(List<PeriodGradeModel> grades) =>
      ops.savePeriodGrades(localDatabase, grades);

  @override
  Future<void> updateTransmutedGrade(
    String classId,
    String studentId,
    int gradingPeriodNumber,
    int transmutedGrade,
  ) =>
      ops.updateTransmutedGrade(
        localDatabase,
        syncQueue,
        classId,
        studentId,
        gradingPeriodNumber,
        transmutedGrade,
      );

  @override
  Future<List<Map<String, dynamic>>> getCachedGradeSummary(
    String classId,
    int gradingPeriodNumber,
  ) =>
      ops.getCachedGradeSummary(localDatabase, classId, gradingPeriodNumber);

  @override
  Future<void> cacheGradeSummary(
    String classId,
    int gradingPeriodNumber,
    List<Map<String, dynamic>> summary,
  ) =>
      ops.cacheGradeSummary(localDatabase, classId, gradingPeriodNumber, summary);

  @override
  Future<List<Map<String, dynamic>>> getCachedFinalGrades(String classId) =>
      ops.getCachedFinalGrades(localDatabase, classId);

  @override
  Future<void> cacheFinalGrades(String classId, List<Map<String, dynamic>> data) =>
      ops.cacheFinalGrades(localDatabase, classId, data);

  @override
  Future<Map<String, dynamic>> getCachedGeneralAverages(String classId) =>
      ops.getCachedGeneralAverages(localDatabase, classId);

  @override
  Future<void> cacheGeneralAverages(String classId, Map<String, dynamic> data) =>
      ops.cacheGeneralAverages(localDatabase, classId, data);

  @override
  Future<Map<String, dynamic>> getCachedMyGradeDetail(
    String classId,
    int gradingPeriodNumber,
  ) =>
      ops.getCachedMyGradeDetail(localDatabase, classId, gradingPeriodNumber);

  @override
  Future<void> cacheMyGradeDetail(
    String classId,
    int gradingPeriodNumber,
    Map<String, dynamic> data,
  ) =>
      ops.cacheMyGradeDetail(localDatabase, classId, gradingPeriodNumber, data);

  @override
  Future<Map<String, dynamic>> getCachedSf9(String classId, String studentId) =>
      ops.getCachedSf9(localDatabase, classId, studentId);

  @override
  Future<void> cacheSf9(String classId, String studentId, Map<String, dynamic> data) =>
      ops.cacheSf9(localDatabase, classId, studentId, data);

  @override
  Future<Map<String, dynamic>> getCachedSf10(String classId, String studentId) =>
      ops.getCachedSf10(localDatabase, classId, studentId);

  @override
  Future<void> cacheSf10(String classId, String studentId, Map<String, dynamic> data) =>
      ops.cacheSf10(localDatabase, classId, studentId, data);

  @override
  Future<void> clearAllCache() =>
      ops.clearAllCache(localDatabase);
}
