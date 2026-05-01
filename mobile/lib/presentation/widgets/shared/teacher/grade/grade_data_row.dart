import 'package:flutter/material.dart';
import 'package:likha/core/theme/app_colors.dart';
import 'package:likha/core/utils/transmutation_util.dart';
import 'package:likha/domain/classes/entities/class_detail.dart';
import 'package:likha/domain/grading/entities/grade_item.dart';
import 'package:likha/domain/grading/entities/grade_score.dart';
import 'package:likha/presentation/pages/shared/grade_skeleton_cell.dart';
import 'package:likha/presentation/widgets/shared/teacher/grade/grade_spreadsheet_cells.dart';

/// Single student row for the grade spreadsheet.
///
/// Renders score cells for all three grade components plus the computed
/// initial-grade, quarterly-grade, and remarks columns.
class GradeDataRow extends StatelessWidget {
  final int index;
  final Participant participant;
  final List<GradeItem> wwItems;
  final List<GradeItem> ptItems;
  final List<GradeItem> qaItems;
  final Map<String, Map<String, GradeScore>> scoreLookup;
  final Map<String, int?> qgLookup;
  final double wwWeight;
  final double ptWeight;
  final double qaWeight;
  final bool isLoadingScores;
  final GradeSpreadsheetDimensions dimensions;

  final String? editingKey;
  final String? editingQgStudentId;
  final TextEditingController scoreCtrl;
  final FocusNode scoreFocus;
  final TextEditingController qgCtrl;
  final FocusNode qgFocus;

  final void Function(String studentId, String itemId, GradeScore? existing)
      onStartScore;
  final VoidCallback onCommitScore;
  final VoidCallback onClearScore;
  final void Function(String studentId, int? current) onStartQg;
  final VoidCallback onCommitQg;
  final VoidCallback onCancelQg;

  const GradeDataRow({
    super.key,
    required this.index,
    required this.participant,
    required this.wwItems,
    required this.ptItems,
    required this.qaItems,
    required this.scoreLookup,
    required this.qgLookup,
    required this.wwWeight,
    required this.ptWeight,
    required this.qaWeight,
    required this.isLoadingScores,
    required this.dimensions,
    required this.editingKey,
    required this.editingQgStudentId,
    required this.scoreCtrl,
    required this.scoreFocus,
    required this.qgCtrl,
    required this.qgFocus,
    required this.onStartScore,
    required this.onCommitScore,
    required this.onClearScore,
    required this.onStartQg,
    required this.onCommitQg,
    required this.onCancelQg,
  });

  @override
  Widget build(BuildContext context) {
    final sid = participant.student.id;
    final bgColor = index.isEven
        ? AppColors.backgroundPrimary
        : AppColors.backgroundTertiary;

    final wwStats = _computeStats(sid, wwItems, wwWeight);
    final ptStats = _computeStats(sid, ptItems, ptWeight);
    final qaStats = _computeStats(sid, qaItems, qaWeight);

    final available =
        [wwStats.ws, ptStats.ws, qaStats.ws].whereType<double>().toList();
    final double? initialGrade = available.isNotEmpty
        ? available.fold<double>(0.0, (sum, v) => sum + v)
        : null;

    final storedQg = qgLookup[sid];
    final computedQg = initialGrade != null
        ? TransmutationUtil.transmute(initialGrade).round()
        : null;
    final displayQg = storedQg ?? computedQg;
    final remarks =
        displayQg != null ? (displayQg >= 75 ? 'Passed' : 'Failed') : null;
    final isEditingQg = editingQgStudentId == sid;

    return SizedBox(
      height: dimensions.rowH,
      child: Row(
        children: [
          ..._buildSectionCells(sid, wwItems, wwStats, bgColor),
          ..._buildSectionCells(sid, ptItems, ptStats, bgColor),
          ..._buildSectionCells(sid, qaItems, qaStats, bgColor),
          GradeComputedCell(
            text: initialGrade != null ? _fmt(initialGrade) : '--',
            width: dimensions.initGradeW,
            height: dimensions.rowH,
            bold: true,
          ),
          if (isEditingQg)
            GradeInlineEditCell(
              ctrl: qgCtrl,
              focus: qgFocus,
              onCommit: onCommitQg,
              onCancel: onCancelQg,
              width: dimensions.qgColW,
              height: dimensions.rowH,
              bgColor: bgColor,
            )
          else
            GestureDetector(
              onTap: () => onStartQg(sid, displayQg),
              child: GradeComputedCell(
                text: displayQg?.toString() ?? '--',
                width: dimensions.qgColW,
                height: dimensions.rowH,
                bold: true,
                color: storedQg != null
                    ? AppColors.accentCharcoal
                    : (displayQg != null ? AppColors.foregroundPrimary : null),
              ),
            ),
          GradeRemarksCell(
            remarks: remarks,
            bgColor: bgColor,
            width: dimensions.remarksW,
            height: dimensions.rowH,
          ),
        ],
      ),
    );
  }

  List<Widget> _buildSectionCells(
    String sid,
    List<GradeItem> items,
    GradeScoreStats stats,
    Color bgColor,
  ) {
    final studentScores = scoreLookup[sid] ?? {};

    return [
      for (final item in items) _buildScoreCell(sid, item, studentScores, bgColor),
      isLoadingScores
          ? GradeSkeletonCell(
              width: dimensions.sumColW,
              height: dimensions.rowH,
            )
          : GradeComputedCell(
              text: stats.total != null ? _fmt(stats.total!) : '--',
              width: dimensions.sumColW,
              height: dimensions.rowH,
            ),
      isLoadingScores
          ? GradeSkeletonCell(
              width: dimensions.sumColW,
              height: dimensions.rowH,
            )
          : GradeComputedCell(
              text: items.isNotEmpty ? _fmt(stats.hs) : '--',
              width: dimensions.sumColW,
              height: dimensions.rowH,
            ),
      isLoadingScores
          ? GradeSkeletonCell(
              width: dimensions.pctColW,
              height: dimensions.rowH,
            )
          : GradeComputedCell(
              text: stats.pct != null
                  ? '${stats.pct!.toStringAsFixed(1)}%'
                  : '--',
              width: dimensions.pctColW,
              height: dimensions.rowH,
            ),
      isLoadingScores
          ? GradeSkeletonCell(
              width: dimensions.pctColW,
              height: dimensions.rowH,
            )
          : GradeComputedCell(
              text: stats.ws != null ? _fmt(stats.ws!) : '--',
              width: dimensions.pctColW,
              height: dimensions.rowH,
              bold: true,
            ),
    ];
  }

  Widget _buildScoreCell(
    String sid,
    GradeItem item,
    Map<String, GradeScore> studentScores,
    Color bgColor,
  ) {
    if (isLoadingScores) {
      return GradeSkeletonCell(
        width: dimensions.scoreColW,
        height: dimensions.rowH,
      );
    }
    final gs = studentScores[item.id];
    final cellKey = '${sid}_${item.id}';
    final isEditing = editingKey == cellKey;

    if (isEditing) {
      return GradeInlineEditCell(
        ctrl: scoreCtrl,
        focus: scoreFocus,
        onCommit: onCommitScore,
        onCancel: onClearScore,
        width: dimensions.scoreColW,
        height: dimensions.rowH,
        bgColor: bgColor,
      );
    }
    return GestureDetector(
      onTap: () => onStartScore(sid, item.id, gs),
      child: GradeScoreCell(
        text: gs?.effectiveScore != null ? _fmt(gs!.effectiveScore!) : '--',
        width: dimensions.scoreColW,
        height: dimensions.rowH,
        bgColor: bgColor,
        isOverride: gs?.overrideScore != null,
        empty: gs?.effectiveScore == null,
      ),
    );
  }

  GradeScoreStats _computeStats(
      String sid, List<GradeItem> items, double weight) {
    final studentScores = scoreLookup[sid] ?? {};
    double total = 0;
    double hs = 0;
    bool hasScore = false;
    for (final item in items) {
      hs += item.totalPoints;
      final score = studentScores[item.id]?.effectiveScore;
      if (score != null) {
        total += score;
        hasScore = true;
      }
    }
    if (!hasScore || hs == 0) {
      return GradeScoreStats(total: null, hs: hs, pct: null, ws: null);
    }
    final pct = (total / hs) * 100;
    return GradeScoreStats(
        total: total, hs: hs, pct: pct, ws: pct * weight / 100);
  }

  static String _fmt(double v) {
    if (v == v.roundToDouble()) return v.toInt().toString();
    return v.toStringAsFixed(1);
  }
}
