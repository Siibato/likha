import 'package:likha/data/models/grading/grade_config_model.dart';
import 'package:likha/data/models/grading/grade_item_model.dart';
import 'package:likha/data/models/grading/grade_score_model.dart';
import 'package:likha/data/models/grading/period_grade_model.dart';
import 'package:likha/domain/grading/entities/grade_config.dart';
import 'package:likha/domain/grading/entities/grade_item.dart';
import 'package:likha/domain/grading/entities/grade_score.dart';
import 'package:likha/domain/grading/entities/period_grade.dart';

/// DepEd weight presets — mirrors class_grading_setup_page.dart
const weightPresets = {
  'language': (ww: 30.0, pt: 50.0, qa: 20.0),
  'ap_esp': (ww: 30.0, pt: 50.0, qa: 20.0),
  'math_sci': (ww: 40.0, pt: 40.0, qa: 20.0),
  'mapeh_tle': (ww: 20.0, pt: 60.0, qa: 20.0),
  'shs_core': (ww: 25.0, pt: 50.0, qa: 25.0),
  'shs_academic': (ww: 25.0, pt: 45.0, qa: 30.0),
  'shs_tvl': (ww: 25.0, pt: 45.0, qa: 30.0),
  'shs_immersion': (ww: 35.0, pt: 40.0, qa: 25.0),
};

GradeConfig configToEntity(GradeConfigModel m) => GradeConfig(
      id: m.id,
      classId: m.classId,
      termNumber: m.termNumber,
      wwWeight: m.wwWeight,
      ptWeight: m.ptWeight,
      qaWeight: m.qaWeight,
    );

GradeItem itemToEntity(GradeItemModel m) => GradeItem(
      id: m.id,
      classId: m.classId,
      title: m.title,
      component: m.component,
      termNumber: m.termNumber,
      totalPoints: m.totalPoints,
      sourceType: m.sourceType,
      sourceId: m.sourceId,
      orderIndex: m.orderIndex,
      createdAt: m.createdAt,
      updatedAt: m.updatedAt,
    );

GradeScore scoreToEntity(GradeScoreModel m) => GradeScore(
      id: m.id,
      gradeItemId: m.gradeItemId,
      studentId: m.studentId,
      score: m.score,
      isAutoPopulated: m.isAutoPopulated,
      overrideScore: m.overrideScore,
      syncStatus: m.syncStatus ?? 'synced',
    );

bool gradeItemsHaveChanged(List<GradeItem> local, List<GradeItem> remote) {
  if (local.length != remote.length) return true;
  final localById = {for (final i in local) i.id: i};
  for (final r in remote) {
    final l = localById[r.id];
    if (l == null) return true;
    if (l.updatedAt.isBefore(r.updatedAt)) return true;
  }
  return false;
}

PeriodGrade periodToEntity(PeriodGradeModel m) => PeriodGrade(
      id: m.id,
      classId: m.classId,
      studentId: m.studentId,
      termNumber: m.termNumber,
      initialGrade: m.initialGrade,
      transmutedGrade: m.transmutedGrade,
      isLocked: m.isLocked,
    );
