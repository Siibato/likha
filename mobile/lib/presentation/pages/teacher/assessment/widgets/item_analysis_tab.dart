import 'package:flutter/material.dart';
import 'package:likha/core/theme/app_colors.dart';
import 'package:likha/domain/assessments/entities/assessment_statistics.dart';
import 'package:likha/presentation/pages/teacher/assessment/widgets/item_analysis_card.dart';
import 'package:likha/presentation/pages/teacher/assessment/widgets/item_analysis_print.dart';
import 'package:likha/presentation/pages/teacher/assessment/widgets/test_summary_card.dart';

class ItemAnalysisTab extends StatelessWidget {
  final AssessmentStatistics stats;

  const ItemAnalysisTab({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    if (stats.itemAnalysis.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.analytics_outlined,
                size: 64,
                color: AppColors.foregroundLight,
              ),
              SizedBox(height: 16),
              Text(
                'Not enough data for item analysis',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.foregroundPrimary,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'At least 10 submitted responses are needed for meaningful analysis.',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.foregroundTertiary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (stats.testSummary != null) ...[
            TestSummaryCard(summary: stats.testSummary!),
            const SizedBox(height: 20),
          ],
          Row(
            children: [
              Expanded(
                child: Text(
                  'Item Analysis (${stats.itemAnalysis.length} items)',
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: AppColors.foregroundDark,
                    letterSpacing: -0.3,
                  ),
                ),
              ),
              GestureDetector(
                onTap: () => ItemAnalysisPrintService.printReport(context, stats),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.accentCharcoal,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.print_outlined, size: 14, color: Colors.white),
                      SizedBox(width: 4),
                      Text(
                        'Print',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...stats.itemAnalysis.asMap().entries.map(
                (entry) => ItemAnalysisCard(
                  index: entry.key,
                  item: entry.value,
                ),
              ),
        ],
      ),
    );
  }
}
