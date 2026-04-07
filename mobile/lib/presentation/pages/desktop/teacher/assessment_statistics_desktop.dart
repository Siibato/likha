import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:likha/core/theme/app_colors.dart';
import 'package:likha/domain/assessments/entities/assessment_statistics.dart';
import 'package:likha/presentation/pages/desktop/core/desktop_page_scaffold.dart';
import 'package:likha/presentation/pages/desktop/teacher/widgets/statistics_charts.dart';
import 'package:likha/presentation/providers/teacher_assessment_provider.dart';

class AssessmentStatisticsDesktop extends ConsumerStatefulWidget {
  final String assessmentId;

  const AssessmentStatisticsDesktop({super.key, required this.assessmentId});

  @override
  ConsumerState<AssessmentStatisticsDesktop> createState() =>
      _AssessmentStatisticsDesktopState();
}

class _AssessmentStatisticsDesktopState
    extends ConsumerState<AssessmentStatisticsDesktop> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(teacherAssessmentProvider.notifier)
          .loadStatistics(widget.assessmentId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(teacherAssessmentProvider);
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
                            Expanded(child: _buildLeftColumn(stats)),
                            const SizedBox(width: 24),
                            Expanded(child: _buildRightColumn(stats)),
                          ],
                        ),
                        const SizedBox(height: 24),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: ScoreDistributionChart(
                                scoreDistribution:
                                    stats.classStatistics.scoreDistribution,
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
                      ],
                    ),
                  ),
      ),
    );
  }

  Widget _buildLeftColumn(AssessmentStatistics stats) {
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
          const SizedBox(height: 20),
          _buildInfoRow('Mean', cs.mean.toStringAsFixed(1)),
          _buildInfoRow('Median', cs.median.toStringAsFixed(1)),
          _buildInfoRow('Highest', cs.highest.toStringAsFixed(1)),
          _buildInfoRow('Lowest', cs.lowest.toStringAsFixed(1)),
          if (stats.testSummary != null) ...[
            const SizedBox(height: 24),
            const Divider(color: AppColors.borderLight),
            const SizedBox(height: 16),
            const Text(
              'Test Summary',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.foregroundDark,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 20),
            _buildInfoRow(
              'Mean Difficulty',
              stats.testSummary!.meanDifficulty.toStringAsFixed(1),
            ),
            _buildInfoRow(
              'Mean Discrimination',
              stats.testSummary!.meanDiscrimination.toStringAsFixed(1),
            ),
            _buildInfoRow(
              'Retain',
              stats.testSummary!.retainCount.toString(),
            ),
            _buildInfoRow(
              'Revise',
              stats.testSummary!.reviseCount.toString(),
            ),
            _buildInfoRow(
              'Discard',
              stats.testSummary!.discardCount.toString(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
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
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.foregroundPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRightColumn(AssessmentStatistics stats) {
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
          const SizedBox(height: 20),
          stats.itemAnalysis.isEmpty
              ? const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: Text(
                      'No item analysis data',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.foregroundTertiary,
                      ),
                    ),
                  ),
                )
              : SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
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
                      DataColumn(label: Text('Question')),
                      DataColumn(label: Text('Difficulty')),
                      DataColumn(label: Text('Discrimination')),
                      DataColumn(label: Text('Verdict')),
                    ],
                    rows: stats.itemAnalysis.map((item) {
                      return DataRow(cells: [
                        DataCell(
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 180),
                            child: Text(
                              item.questionText,
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                        ),
                        DataCell(
                          Text(
                            '${item.difficultyIndex.toStringAsFixed(2)} (${item.difficultyLabel})',
                          ),
                        ),
                        DataCell(
                          Text(
                            '${item.discriminationIndex.toStringAsFixed(2)} (${item.discriminationLabel})',
                          ),
                        ),
                        DataCell(_buildVerdictBadge(item.verdict)),
                      ]);
                    }).toList(),
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
        backgroundColor = const Color(0xFFFFF8E1);
        textColor = const Color(0xFFF9A825);
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
