import 'package:flutter/material.dart';
import 'package:likha/core/theme/app_colors.dart';
import 'package:likha/domain/assessments/entities/assessment_statistics.dart';
import 'package:likha/presentation/widgets/shared/cards/base_stats_card.dart';

class ClassPerformanceCard extends StatelessWidget {
  final ClassStatistics classStats;

  const ClassPerformanceCard({
    super.key,
    required this.classStats,
  });

  @override
  Widget build(BuildContext context) {
    return BaseStatsCard(
      title: 'Class Performance',
      value: classStats.mean.toStringAsFixed(1),
      subtitle: 'Mean Score',
      icon: Icons.analytics_outlined,
      iconColor: AppColors.accentCharcoal,
      margin: const EdgeInsets.only(bottom: 14),
    );
  }
}