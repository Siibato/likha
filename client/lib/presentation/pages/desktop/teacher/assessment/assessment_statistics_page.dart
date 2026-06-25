import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:likha/core/theme/app_colors.dart';
import 'package:likha/domain/assessments/entities/assessment_statistics.dart';
import 'package:likha/presentation/layouts/desktop/desktop_page_scaffold.dart';
import 'package:likha/presentation/widgets/desktop/teacher/assessment/statistics_charts.dart';
import 'package:likha/presentation/providers/assessment/statistics_notifier.dart';

class AssessmentStatisticsPage extends ConsumerStatefulWidget {
  final String assessmentId;

  const AssessmentStatisticsPage({super.key, required this.assessmentId});

  @override
  ConsumerState<AssessmentStatisticsPage> createState() =>
      _AssessmentStatisticsPageState();
}

class _AssessmentStatisticsPageState
    extends ConsumerState<AssessmentStatisticsPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(statisticsProvider.notifier)
          .loadStatistics(widget.assessmentId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(statisticsProvider);
    final stats = state.statistics;

    return Scaffold(
      backgroundColor: AppColors.backgroundSecondary,
      body: DesktopPageScaffold(
        title: 'Assessment Statistics',
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.foregroundPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        body: state.isLoading && stats == null
            ? const Center(
                child: Padding(
                  padding: EdgeInsets.all(48),
                  child: CircularProgressIndicator(
                    color: AppColors.foregroundPrimary,
                    strokeWidth: 2.5,
                  ),
                ),
              )
            : stats == null
                ? const Center(
                    child: Text(
                      'No statistics available',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: AppColors.foregroundTertiary,
                      ),
                    ),
                  )
                : SingleChildScrollView(
                    child: Column(
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                                child: _buildClassPerformanceCard(stats)),
                            const SizedBox(width: 24),
                            Expanded(
                              child: ScoreDistributionChart(
                                scoreDistribution:
                                    stats.classStatistics.scoreDistribution,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          child: _buildQuestionStatsCard(stats),
                        ),
                        const SizedBox(height: 24),
                        if (stats.itemAnalysis.isNotEmpty) ...[
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: ItemDiscriminationChart(
                                  items: stats.itemAnalysis,
                                ),
                              ),
                              const SizedBox(width: 24),
                              Expanded(
                                child: ItemDifficultyChart(
                                  items: stats.itemAnalysis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          SizedBox(
                            width: double.infinity,
                            child: _buildItemAnalysisCard(stats),
                          ),
                        ],
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
      ),
    );
  }

  Widget _buildClassPerformanceCard(AssessmentStatistics stats) {
    final cs = stats.classStatistics;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Class Performance',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.foregroundDark,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${stats.submissionCount} submissions',
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.foregroundTertiary,
            ),
          ),
          const SizedBox(height: 20),
          _buildInfoRow('Mean', cs.mean.toStringAsFixed(1)),
          _buildInfoRow('Median', cs.median.toStringAsFixed(1)),
          _buildInfoRow('Std Dev', cs.stdDev.toStringAsFixed(1)),
          _buildInfoRow('Highest', cs.highest.toStringAsFixed(1)),
          _buildInfoRow('Lowest', cs.lowest.toStringAsFixed(1)),
          const SizedBox(height: 16),
          const Divider(color: AppColors.borderLight),
          const SizedBox(height: 16),
          _buildInfoRow(
            'Pass Rate (≥75%)',
            '${cs.passRate.toStringAsFixed(1)}%',
            valueColor: cs.passRate >= 75
                ? AppColors.semanticSuccess
                : AppColors.semanticError,
          ),
          _buildInfoRow(
            'Fail Rate (<75%)',
            '${cs.failRate.toStringAsFixed(1)}%',
            valueColor: cs.failRate > 50
                ? AppColors.semanticError
                : AppColors.foregroundPrimary,
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionStatsCard(AssessmentStatistics stats) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Question Performance',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.foregroundDark,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Correct vs incorrect per question',
            style: TextStyle(
              fontSize: 13,
              color: AppColors.foregroundTertiary,
            ),
          ),
          const SizedBox(height: 20),
          stats.questionStatistics.isEmpty
              ? const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: Text(
                      'No question data',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.foregroundTertiary,
                      ),
                    ),
                  ),
                )
              : DataTable(
                  headingRowColor: WidgetStateProperty.all(
                    AppColors.backgroundSecondary,
                  ),
                  headingTextStyle: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.foregroundPrimary,
                  ),
                  dataTextStyle: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    color: AppColors.foregroundPrimary,
                  ),
                  columnSpacing: 20,
                  columns: const [
                    DataColumn(label: Expanded(child: Text('Question'))),
                    DataColumn(label: Text('Correct'), numeric: true),
                    DataColumn(label: Text('Incorrect'), numeric: true),
                    DataColumn(label: Text('% Correct'), numeric: true),
                    DataColumn(label: Text('Avg Points'), numeric: true),
                    DataColumn(label: Text('Avg %'), numeric: true),
                  ],
                  rows: stats.questionStatistics.map((q) {
                    return DataRow(cells: [
                      DataCell(
                        Text(q.questionText),
                      ),
                        DataCell(Text('${q.correctCount}')),
                        DataCell(Text('${q.incorrectCount}')),
                        DataCell(
                          Text(
                            '${q.correctPercentage.toStringAsFixed(1)}%',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: q.correctPercentage >= 75
                                  ? AppColors.semanticSuccess
                                  : q.correctPercentage >= 50
                                      ? AppColors.accentAmber
                                      : AppColors.semanticError,
                            ),
                          ),
                        ),
                        DataCell(
                          Text(
                            q.averagePoints.toStringAsFixed(1),
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                        DataCell(
                          Text(
                            '${q.averagePercentage.toStringAsFixed(1)}%',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: q.averagePercentage >= 75
                                  ? AppColors.semanticSuccess
                                  : q.averagePercentage >= 50
                                      ? AppColors.accentAmber
                                      : AppColors.semanticError,
                            ),
                          ),
                        ),
                      ]);
                    }).toList(),
                  ),
        ],
      ),
    );
  }

  Widget _buildItemAnalysisCard(AssessmentStatistics stats) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Item Analysis',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.foregroundDark,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Difficulty = % correct (higher = easier) · Discrimination = upper vs lower group gap · Verdict per DepEd standard',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.foregroundTertiary,
            ),
          ),
          const SizedBox(height: 20),
          stats.itemAnalysis.isEmpty
              ? const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: Text(
                      'No item analysis data (requires ≥10 submissions)',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.foregroundTertiary,
                      ),
                    ),
                  ),
                )
              : _buildItemAnalysisTable(stats.itemAnalysis),
        ],
      ),
    );
  }

  Widget _buildItemAnalysisTable(List<ItemAnalysis> items) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Theme(
          data: Theme.of(context).copyWith(dividerColor: AppColors.borderLight),
          child: ConstrainedBox(
            constraints: BoxConstraints(minWidth: constraints.maxWidth),
            child: DataTable(
              headingRowColor: WidgetStateProperty.all(
                AppColors.backgroundSecondary,
              ),
              headingTextStyle: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.foregroundPrimary,
              ),
              dataTextStyle: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w400,
                color: AppColors.foregroundPrimary,
              ),
              columnSpacing: 24,
              columns: const [
                DataColumn(label: Expanded(child: Text('Question'))),
                DataColumn(label: Text('Difficulty'), numeric: true),
                DataColumn(label: Text('Discrimination'), numeric: true),
                DataColumn(label: Text('Verdict')),
                // DataColumn(label: Text('Distractors')),
              ],
        rows: items.map((item) {
          return DataRow(
            cells: [
              DataCell(
                Text(item.questionText),
              ),
                DataCell(
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        item.difficultyIndex.toStringAsFixed(2),
                        style: const TextStyle(fontSize: 12),
                      ),
                      Text(
                        item.difficultyLabel,
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.foregroundTertiary,
                        ),
                      ),
                    ],
                  ),
                ),
                DataCell(
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        item.discriminationIndex.toStringAsFixed(2),
                        style: const TextStyle(fontSize: 12),
                      ),
                      Text(
                        item.discriminationLabel,
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.foregroundTertiary,
                        ),
                      ),
                    ],
                  ),
                ),
                DataCell(_buildVerdictBadge(item.verdict)),
                // DataCell(_buildDistractorCell(item.distractors)),
              ],
            );
          }).toList(),
        ),
          ),
        );
      },
    );
  }

  // Widget _buildDistractorCell(List<DistractorAnalysis>? distractors) {
  //   if (distractors == null || distractors.isEmpty) {
  //     return const Text(
  //       '—',
  //       style: TextStyle(color: AppColors.foregroundTertiary),
  //     );
  //   }
  //
  //   return Wrap(
  //     spacing: 6,
  //     runSpacing: 4,
  //     children: distractors.map((d) {
  //         final color = d.isCorrect
  //             ? AppColors.semanticSuccess
  //             : d.isEffective
  //                 ? AppColors.foregroundTertiary
  //                 : AppColors.semanticError;
  //
  //         return Tooltip(
  //           message: d.isCorrect
  //               ? 'Correct answer — ${d.totalPercentage.toStringAsFixed(0)}% chose this'
  //               : d.isEffective
  //                   ? 'Effective distractor — ${d.totalPercentage.toStringAsFixed(0)}% chose this (lower > upper)'
  //                   : 'Ineffective distractor — ${d.totalPercentage.toStringAsFixed(0)}% chose this',
  //           child: Container(
  //             padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
  //             decoration: BoxDecoration(
  //               color: color.withValues(alpha: 0.08),
  //               borderRadius: BorderRadius.circular(4),
  //               border: Border.all(color: color.withValues(alpha: 0.2)),
  //             ),
  //             child: Text(
  //               '${d.totalPercentage.toStringAsFixed(0)}%',
  //               style: TextStyle(
  //                 fontSize: 11,
  //                 fontWeight: FontWeight.w600,
  //                 color: color,
  //               ),
  //             ),
  //           ),
  //         );
  //       }).toList(),
  //   );
  // }

  Widget _buildInfoRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColors.foregroundSecondary,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: valueColor ?? AppColors.foregroundPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVerdictBadge(String verdict) {
    final Color backgroundColor;
    final Color textColor;

    switch (verdict.toLowerCase()) {
      case 'retain':
        backgroundColor = AppColors.semanticSuccessBackground;
        textColor = AppColors.semanticSuccess;
        break;
      case 'revise':
        backgroundColor = AppColors.accentAmber.withValues(alpha: 0.08);
        textColor = AppColors.accentAmber;
        break;
      case 'discard':
        backgroundColor = AppColors.semanticErrorBackground;
        textColor = AppColors.semanticError;
        break;
      default:
        backgroundColor = AppColors.backgroundDisabled;
        textColor = AppColors.foregroundSecondary;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        verdict,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }
}
