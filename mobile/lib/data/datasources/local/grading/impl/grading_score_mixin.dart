import 'package:likha/data/models/grading/grade_score_model.dart';
import '../grading_local_datasource_base.dart';
import 'operations/grade_score/get_scores_by_item.dart';
import 'operations/grade_score/save_scores.dart';
import 'operations/grade_score/upsert_scores_by_item.dart';
import 'operations/grade_score/update_score_override.dart';

mixin GradingScoreMixin on GradingLocalDataSourceBase {
  @override
  Future<List<GradeScoreModel>> getScoresByItem(String gradeItemId) async {
    return getScoresByItemOp(localDatabase, gradeItemId);
  }

  @override
  Future<void> saveScores(List<GradeScoreModel> scores) async {
    return saveScoresOp(localDatabase, scores);
  }

  @override
  Future<void> upsertScoresByItem(
    String gradeItemId,
    List<GradeScoreModel> scores,
  ) async {
    return upsertScoresByItemOp(localDatabase, syncQueue, gradeItemId, scores);
  }

  @override
  Future<void> updateScoreOverride(
      String scoreId, double? overrideScore) async {
    return updateScoreOverrideOp(localDatabase, syncQueue, scoreId, overrideScore);
  }
}
