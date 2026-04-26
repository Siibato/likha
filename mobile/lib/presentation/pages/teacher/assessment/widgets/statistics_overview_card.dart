import 'package:flutter/material.dart';
import 'package:likha/core/theme/app_colors.dart';

class StatisticsOverviewCard extends StatelessWidget {
  final String title;
  final int totalPoints;
  final int submissionCount;

  const StatisticsOverviewCard({
    super.key,
    required this.title,
    required this.totalPoints,
    required this.submissionCount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.borderLight,
          width: 1,
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.foregroundDark,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _StatItem(label: 'Total Points', value: '$totalPoints'),
              _StatItem(label: 'Submissions', value: '$submissionCount'),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;

  const _StatItem({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w700,
            color: AppColors.foregroundPrimary,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            color: AppColors.foregroundTertiary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}