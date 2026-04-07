import 'package:flutter/material.dart';
import 'package:likha/core/theme/app_colors.dart';
import 'package:likha/domain/classes/entities/class_detail.dart';
import 'package:likha/domain/grading/entities/grade_item.dart';
import 'package:likha/domain/grading/entities/grade_score.dart';

class GradeSpreadsheet extends StatelessWidget {
  final List<Participant> students;
  final List<GradeItem> items;
  final Map<String, List<GradeScore>> scoresByItem;
  final String weightLabel;
  final void Function(Participant participant, GradeItem item,
      GradeScore? existingScore) onCellTap;
  final void Function(GradeItem item) onHeaderTap;

  const GradeSpreadsheet({
    super.key,
    required this.students,
    required this.items,
    required this.scoresByItem,
    required this.weightLabel,
    required this.onCellTap,
    required this.onHeaderTap,
  });

  static const double _frozenColWidth = 180;
  static const double _itemColWidth = 80;
  static const double _rowHeight = 44;
  static const double _headerHeight = 56;

  /// Build a lookup: studentId -> { gradeItemId -> GradeScore }
  Map<String, Map<String, GradeScore>> _buildScoreLookup() {
    final lookup = <String, Map<String, GradeScore>>{};
    for (final entry in scoresByItem.entries) {
      for (final score in entry.value) {
        lookup
            .putIfAbsent(score.studentId, () => <String, GradeScore>{})
            [score.gradeItemId] = score;
      }
    }
    return lookup;
  }

  String _formatScore(double value) {
    if (value == value.truncateToDouble()) {
      return value.toInt().toString();
    }
    return value.toStringAsFixed(1);
  }

  double? _computePercentage(
    Participant participant,
    Map<String, Map<String, GradeScore>> scoreLookup,
  ) {
    if (items.isEmpty) return null;

    final studentScores = scoreLookup[participant.student.id];
    if (studentScores == null || studentScores.isEmpty) return null;

    double totalEarned = 0;
    double totalPossible = 0;

    for (final item in items) {
      final score = studentScores[item.id];
      final effective = score?.effectiveScore;
      if (effective != null) {
        totalEarned += effective;
        totalPossible += item.totalPoints;
      }
    }

    if (totalPossible == 0) return null;
    return (totalEarned / totalPossible) * 100;
  }

  @override
  Widget build(BuildContext context) {
    final scoreLookup = _buildScoreLookup();
    final scrollController = ScrollController();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Weight label
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(
            weightLabel,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.foregroundPrimary,
            ),
          ),
        ),
        // Spreadsheet
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Frozen first column (student names)
              _buildFrozenColumn(scoreLookup),
              // Scrollable item columns + percentage column
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  scrollDirection: Axis.horizontal,
                  child: _buildScrollableColumns(scoreLookup),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFrozenColumn(
      Map<String, Map<String, GradeScore>> scoreLookup) {
    return SizedBox(
      width: _frozenColWidth,
      child: Column(
        children: [
          // Header cell
          Container(
            height: _headerHeight,
            width: _frozenColWidth,
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: const BoxDecoration(
              color: AppColors.backgroundTertiary,
              border: Border(
                bottom: BorderSide(color: AppColors.borderLight),
                right: BorderSide(color: AppColors.borderLight),
              ),
            ),
            child: const Text(
              'Student',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.foregroundPrimary,
              ),
            ),
          ),
          // Student name rows
          Expanded(
            child: ListView.builder(
              itemCount: students.length,
              itemExtent: _rowHeight,
              itemBuilder: (context, index) {
                final student = students[index];
                return Container(
                  width: _frozenColWidth,
                  height: _rowHeight,
                  alignment: Alignment.centerLeft,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: index.isEven
                        ? AppColors.backgroundPrimary
                        : AppColors.backgroundTertiary,
                    border: const Border(
                      bottom: BorderSide(color: AppColors.borderLight),
                      right: BorderSide(color: AppColors.borderLight),
                    ),
                  ),
                  child: Text(
                    student.student.fullName,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.foregroundPrimary,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScrollableColumns(
      Map<String, Map<String, GradeScore>> scoreLookup) {
    final totalWidth =
        (items.length * _itemColWidth) + _itemColWidth; // +1 for percentage col

    return SizedBox(
      width: totalWidth,
      child: Column(
        children: [
          // Header row
          SizedBox(
            height: _headerHeight,
            child: Row(
              children: [
                // Item headers
                ...items.map((item) => _buildItemHeader(item)),
                // Percentage header
                Container(
                  width: _itemColWidth,
                  height: _headerHeight,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    color: AppColors.backgroundTertiary,
                    border: Border(
                      bottom: BorderSide(color: AppColors.borderLight),
                      right: BorderSide(color: AppColors.borderLight),
                    ),
                  ),
                  child: const Text(
                    '%',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.foregroundPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Data rows
          Expanded(
            child: ListView.builder(
              itemCount: students.length,
              itemExtent: _rowHeight,
              itemBuilder: (context, index) {
                final participant = students[index];
                final studentScores =
                    scoreLookup[participant.student.id] ?? {};
                final percentage =
                    _computePercentage(participant, scoreLookup);

                return SizedBox(
                  height: _rowHeight,
                  child: Row(
                    children: [
                      // Score cells
                      ...items.map((item) {
                        final score = studentScores[item.id];
                        return _buildScoreCell(
                          participant: participant,
                          item: item,
                          score: score,
                          rowIndex: index,
                        );
                      }),
                      // Percentage cell
                      Container(
                        width: _itemColWidth,
                        height: _rowHeight,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: index.isEven
                              ? AppColors.backgroundPrimary
                              : AppColors.backgroundTertiary,
                          border: const Border(
                            bottom: BorderSide(color: AppColors.borderLight),
                            right: BorderSide(color: AppColors.borderLight),
                          ),
                        ),
                        child: Text(
                          percentage != null
                              ? '${_formatScore(percentage)}%'
                              : '--',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: percentage != null
                                ? AppColors.foregroundPrimary
                                : AppColors.foregroundTertiary,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemHeader(GradeItem item) {
    return GestureDetector(
      onTap: () => onHeaderTap(item),
      child: Container(
        width: _itemColWidth,
        height: _headerHeight,
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 4),
        decoration: const BoxDecoration(
          color: AppColors.backgroundTertiary,
          border: Border(
            bottom: BorderSide(color: AppColors.borderLight),
            right: BorderSide(color: AppColors.borderLight),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              item.title,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.foregroundPrimary,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 2),
            Text(
              '/${_formatScore(item.totalPoints)}',
              style: const TextStyle(
                fontSize: 10,
                color: AppColors.foregroundTertiary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScoreCell({
    required Participant participant,
    required GradeItem item,
    required GradeScore? score,
    required int rowIndex,
  }) {
    final effective = score?.effectiveScore;
    final displayText =
        effective != null ? _formatScore(effective) : '--';

    return GestureDetector(
      onTap: () => onCellTap(participant, item, score),
      child: Container(
        width: _itemColWidth,
        height: _rowHeight,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: rowIndex.isEven
              ? AppColors.backgroundPrimary
              : AppColors.backgroundTertiary,
          border: const Border(
            bottom: BorderSide(color: AppColors.borderLight),
            right: BorderSide(color: AppColors.borderLight),
          ),
        ),
        child: Text(
          displayText,
          style: TextStyle(
            fontSize: 12,
            color: effective != null
                ? AppColors.foregroundPrimary
                : AppColors.foregroundTertiary,
          ),
        ),
      ),
    );
  }
}
