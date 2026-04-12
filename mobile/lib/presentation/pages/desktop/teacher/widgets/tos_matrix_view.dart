import 'package:flutter/material.dart';
import 'package:likha/core/theme/app_colors.dart';
import 'package:likha/domain/tos/entities/tos_entity.dart';

class TosMatrixView extends StatelessWidget {
  final List<TosCompetency> competencies;
  final String classificationMode;
  final int totalItems;

  const TosMatrixView({
    super.key,
    required this.competencies,
    required this.classificationMode,
    required this.totalItems,
  });

  List<String> get _cognitiveHeaders => classificationMode == 'blooms'
      ? const ['R', 'U', 'Ap', 'An', 'E', 'C']
      : const ['Easy', 'Avg', 'Diff'];

  int get _totalDays =>
      competencies.fold<int>(0, (sum, c) => sum + (c.timeUnitsTaught as int));

  @override
  Widget build(BuildContext context) {
    final cognitiveHeaders = _cognitiveHeaders;
    final totalDays = _totalDays;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeaderRow(cognitiveHeaders),
            ...competencies.map(
              (c) => _buildDataRow(c, cognitiveHeaders, totalDays),
            ),
            _buildTotalsRow(cognitiveHeaders, totalDays),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderRow(List<String> cognitiveHeaders) {
    return Container(
      color: AppColors.backgroundTertiary,
      child: Row(
        children: [
          _headerCell('Competency', width: 240),
          _headerCell('Days', width: 64),
          _headerCell('%', width: 64),
          ...cognitiveHeaders.map((h) => _headerCell(h, width: 56)),
          _headerCell('Total', width: 64),
        ],
      ),
    );
  }

  Widget _buildDataRow(
    TosCompetency competency,
    List<String> cognitiveHeaders,
    int totalDays,
  ) {
    final weight =
        totalDays > 0 ? (competency.timeUnitsTaught as int) / totalDays * 100 : 0.0;
    final targetItems = (weight * totalItems / 100).round();
    final competencyLabel = competency.competencyCode != null
        ? '${competency.competencyCode} - ${competency.competencyText}'
        : competency.competencyText;

    return Container(
      color: Colors.white,
      child: Row(
        children: [
          _dataCell(competencyLabel, width: 240),
          _dataCell('${competency.timeUnitsTaught as int}', width: 64),
          _dataCell('${weight.toStringAsFixed(1)}%', width: 64),
          ...cognitiveHeaders.map((_) => _dataCell('-', width: 56)),
          _dataCell('$targetItems', width: 64),
        ],
      ),
    );
  }

  Widget _buildTotalsRow(List<String> cognitiveHeaders, int totalDays) {
    return Container(
      color: AppColors.backgroundSecondary,
      child: Row(
        children: [
          _totalsCell('TOTAL', width: 240),
          _totalsCell('$totalDays', width: 64),
          _totalsCell('100%', width: 64),
          ...cognitiveHeaders.map((_) => _totalsCell('-', width: 56)),
          _totalsCell('$totalItems', width: 64),
        ],
      ),
    );
  }

  Widget _headerCell(String text, {required double width}) {
    return SizedBox(
      width: width,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.foregroundSecondary,
          ),
        ),
      ),
    );
  }

  Widget _dataCell(String text, {required double width}) {
    return SizedBox(
      width: width,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 13,
            color: AppColors.foregroundPrimary,
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }

  Widget _totalsCell(String text, {required double width}) {
    return SizedBox(
      width: width,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: AppColors.foregroundPrimary,
          ),
        ),
      ),
    );
  }
}
