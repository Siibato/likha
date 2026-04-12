import 'package:likha/domain/grading/entities/grade_config.dart';
import 'package:likha/domain/grading/entities/grade_item.dart';
import 'package:likha/domain/grading/entities/grade_score.dart';
import 'package:likha/domain/grading/entities/period_grade.dart';
import 'package:likha/core/utils/transmutation_util.dart';

/// Client-side grade computation for offline preview.
/// Mirrors the server algorithm in server/src/services/grade_computation/compute.rs
class GradeComputationUtil {
  /// Compute a preview period grade from local data.
  static PeriodGrade computePreview({
    required GradeConfig config,
    required List<GradeItem> items,
    required Map<String, List<GradeScore>> scoresByItem,
    required String classId,
    required String studentId,
    required int gradingPeriodNumber,
  }) {
    // 1. Group items by component
    final wwItems =
        items.where((i) => i.component == 'written_work').toList();
    final ptItems =
        items.where((i) => i.component == 'performance_task').toList();
    final qaItems =
        items.where((i) => i.component == 'quarterly_assessment').toList();

    // 2. For each component: sum effective scores / sum total_points * 100
    final wwResult = _computeComponent(wwItems, scoresByItem, studentId);
    final ptResult = _computeComponent(ptItems, scoresByItem, studentId);
    final qaResult = _computeComponent(qaItems, scoresByItem, studentId);

    // 3. Apply weights
    final wwWeighted = wwResult.percentage * (config.wwWeight / 100.0);
    final ptWeighted = ptResult.percentage * (config.ptWeight / 100.0);
    final qaWeighted = qaResult.percentage * (config.qaWeight / 100.0);

    // 4. Initial grade = sum of weighted
    final initialGrade = wwWeighted + ptWeighted + qaWeighted;

    // 5. Transmute
    final transmutedGrade = TransmutationUtil.transmute(initialGrade);

    // 6. Check completeness - all items must have scores for this student
    final isComplete = wwResult.isComplete &&
        ptResult.isComplete &&
        qaResult.isComplete &&
        (wwItems.isNotEmpty || ptItems.isNotEmpty || qaItems.isNotEmpty);

    return PeriodGrade(
      id: '', // preview, no real ID
      classId: classId,
      studentId: studentId,
      gradingPeriodNumber: gradingPeriodNumber,
      initialGrade: initialGrade,
      transmutedGrade: transmutedGrade,
      isLocked: isComplete,
      computedAt: DateTime.now().toIso8601String(),
      isPreview: true,
    );
  }

  /// Compute final grade as average of completed period transmuted grades.
  static double? computeFinalGrade(List<PeriodGrade> periodGrades) {
    final complete = periodGrades
        .where((g) => g.isLocked && g.transmutedGrade != null)
        .toList();
    if (complete.isEmpty) return null;
    final sum = complete.fold<double>(0, (s, g) => s + g.transmutedGrade!);
    return sum / complete.length;
  }

  static _ComponentResult _computeComponent(
    List<GradeItem> items,
    Map<String, List<GradeScore>> scoresByItem,
    String studentId,
  ) {
    if (items.isEmpty) return _ComponentResult(0, true);

    double totalScored = 0;
    double totalPossible = 0;
    bool allHaveScores = true;

    for (final item in items) {
      final scores = scoresByItem[item.id] ?? [];
      final studentScore =
          scores.where((s) => s.studentId == studentId).firstOrNull;

      if (studentScore != null && studentScore.effectiveScore != null) {
        totalScored += studentScore.effectiveScore!;
        totalPossible += item.totalPoints;
      } else {
        allHaveScores = false;
        totalPossible += item.totalPoints;
      }
    }

    final percentage =
        totalPossible > 0 ? (totalScored / totalPossible) * 100 : 0.0;
    return _ComponentResult(percentage, allHaveScores);
  }
}

class _ComponentResult {
  final double percentage;
  final bool isComplete;
  _ComponentResult(this.percentage, this.isComplete);
}
