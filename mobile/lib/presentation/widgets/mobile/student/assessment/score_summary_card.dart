import 'package:flutter/material.dart';
import 'package:likha/core/theme/app_colors.dart';
import 'package:likha/domain/assessments/entities/submission.dart';
import 'package:likha/presentation/widgets/shared/cards/base_stats_card.dart';

class ScoreSummaryCard extends StatelessWidget {
  final StudentResult result;

  const ScoreSummaryCard({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    return BaseStatsCard(
      title: 'Your Score',
      value: result.finalScore % 1 == 0
          ? result.finalScore.toInt().toString()
          : result.finalScore.toStringAsFixed(1),
      subtitle: '/ ${result.totalPoints}',
      icon: Icons.assessment_outlined,
      iconColor: AppColors.accentCharcoal,
      margin: const EdgeInsets.only(bottom: 14),
    );
  }
}